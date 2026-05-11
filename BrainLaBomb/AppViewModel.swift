import Foundation
import Combine

enum AppState {
    case home
    case input
    case processingFirst
    case question(String)
    case processingSecond
    case result(DecisionResult)
    case error(String)
}

class AppViewModel: ObservableObject {

    // MARK: - State
    @Published var appState: AppState = .home
    var currentTask: Task<Void, Never>?

    // MARK: - Think Data
    var originalQuestion: String = ""
    var followUpQuestion: String = ""
    var followUpAnswer: String = ""

    // MARK: - History
    @Published var thinkHistory: [Think] = []
    private(set) var currentThinkID: UUID?

    // MARK: - Pattern
    var patternData: PatternData? {
        get {
            guard let data = UserDefaults.standard.data(forKey: "patternData"),
                  let decoded = try? JSONDecoder().decode(PatternData.self, from: data) else { return nil }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: "patternData")
            }
        }
    }

    var thinkCountForPattern: Int { thinkHistory.count }

    // MARK: - Thinks Counter
    var thinksUsed: Int {
        get { UserDefaults.standard.integer(forKey: Constants.thinksUsedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Constants.thinksUsedKey) }
    }

    var thinksRemaining: Int {
        max(0, Constants.maxFreeThinks - thinksUsed)
    }

    var hasThinkRemaining: Bool {
        thinksRemaining > 0
    }

    // MARK: - Init
    init() {
        loadHistory()
    }

    // MARK: - Flow
    func submitQuestion(_ question: String) {
        originalQuestion = question
        appState = .processingFirst

        currentTask = Task {
            do {
                let firstPass = try await APIClient.shared.firstPass(question: question)

                await MainActor.run {
                    if firstPass.needsQuestion && !firstPass.question.isEmpty {
                        self.followUpQuestion = firstPass.question
                        self.appState = .question(firstPass.question)
                    } else {
                        self.appState = .processingSecond
                    }
                }

                if case .processingSecond = await MainActor.run(body: { self.appState }) {
                    await runSecondPass(answer: "")
                }

            } catch {
                await MainActor.run {
                    self.appState = .error(error.localizedDescription)
                }
            }
        }
    }

    func submitFollowUp(answer: String) {
        followUpAnswer = answer
        appState = .processingSecond

        currentTask = Task {
            await runSecondPass(answer: answer)
        }
    }

    func skipFollowUp() {
        submitFollowUp(answer: "")
    }

    private func runSecondPass(answer: String) async {
        do {
            let result = try await APIClient.shared.secondPass(
                question: originalQuestion,
                followUpAnswer: answer,
                thinkHistory: thinkHistory
            )

            await MainActor.run {
                self.thinksUsed += 1
                self.saveThink(result: result)
                self.appState = .result(result)
            }

        } catch {
            await MainActor.run {
                self.appState = .error(error.localizedDescription)
            }
        }
    }

    func reset() {
        currentTask?.cancel()
        currentTask = nil
        originalQuestion = ""
        followUpQuestion = ""
        followUpAnswer = ""
        appState = .home
    }

    func retry() {
        if originalQuestion.isEmpty {
            appState = .home
        } else {
            submitQuestion(originalQuestion)
        }
    }

    // MARK: - Persistence
    private func saveThink(result: DecisionResult) {
        let think = Think(
            originalQuestion: originalQuestion,
            followUpQuestion: followUpQuestion,
            followUpAnswer: followUpAnswer,
            result: result
        )
        thinkHistory.append(think)
        currentThinkID = think.id
        saveHistory()

        if thinkHistory.count >= 5 && thinkHistory.count % 5 == 0 {
            Task { await runPatternAnalysis() }
        }
    }

    private func runPatternAnalysis() async {
        guard !Constants.useMockData else { return }
        do {
            if let newPattern = try await APIClient.shared.analyzePattern(thinkHistory: thinkHistory) {
                await MainActor.run { patternData = newPattern }
            }
        } catch {
            print("Pattern analysis failed: \(error)")
        }
    }

    func refreshPatternIfNeeded() {
        guard thinkHistory.count >= 5 else { return }
        Task { await runPatternAnalysis() }
    }

    #if DEBUG
    func injectMockPatternData() {
        patternData = PatternData(
            identity: PatternIdentity(
                name: "The Night Thinker",
                description: "your biggest decisions happen after the world goes quiet",
                percentage: 19,
                insight: "you don't think better at night. you think more honestly."
            ),
            generatedAt: Date(),
            thinkCount: 7
        )
    }
    #endif

    func updateChatMessages(_ messages: [ChatBubble], forThinkID thinkID: UUID) {
        guard let index = thinkHistory.firstIndex(where: { $0.id == thinkID }) else { return }
        thinkHistory[index].chatMessages = messages
        saveHistory()
    }

    func think(withID id: UUID) -> Think? {
        thinkHistory.first(where: { $0.id == id })
    }

    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(thinkHistory) {
            UserDefaults.standard.set(encoded, forKey: Constants.thinkHistoryKey)
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: Constants.thinkHistoryKey),
              let decoded = try? JSONDecoder().decode([Think].self, from: data) else { return }
        thinkHistory = decoded
    }

    func clearAllData() {
        UserDefaults.standard.removeObject(forKey: Constants.thinkHistoryKey)
        UserDefaults.standard.removeObject(forKey: Constants.thinksUsedKey)
        thinkHistory = []
        objectWillChange.send()
    }
}
