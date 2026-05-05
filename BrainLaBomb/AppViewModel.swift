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

        if let encoded = try? JSONEncoder().encode(thinkHistory) {
            UserDefaults.standard.set(encoded, forKey: Constants.thinkHistoryKey)
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: Constants.thinkHistoryKey),
              let decoded = try? JSONDecoder().decode([Think].self, from: data) else { return }
        thinkHistory = decoded
    }
}
