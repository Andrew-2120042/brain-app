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
    case paywallRequired
}

enum AppTier {
    case free
    case core
    case pro
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
            if let value = newValue,
               let encoded = try? JSONEncoder().encode(value) {
                UserDefaults.standard.set(encoded, forKey: "patternData")
            } else {
                UserDefaults.standard.removeObject(forKey: "patternData")
            }
        }
    }

    var thinkCountForPattern: Int { thinkHistory.count }

    // MARK: - Tier Management

    var currentTier: AppTier {
        // TODO: replace with RevenueCat check when integrated
        #if DEBUG
        return debugTier
        #else
        return .free
        #endif
    }

    #if DEBUG
    @Published var debugTier: AppTier = .free
    #endif

    var coreThinksUsed: Int {
        get { UserDefaults.standard.integer(forKey: "coreThinksUsed") }
        set { UserDefaults.standard.set(newValue, forKey: "coreThinksUsed") }
    }

    var coreThinkLimit: Int { 500 }
    var coreSonnetLimit: Int { 350 }

    var coreThinksRemaining: Int {
        max(0, coreThinkLimit - coreThinksUsed)
    }

    var coreLimitReached: Bool {
        currentTier == .core && coreThinksUsed >= coreThinkLimit
    }

    // MARK: - Thinks Counter

    var thinksUsed: Int {
        get { UserDefaults.standard.integer(forKey: Constants.thinksUsedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Constants.thinksUsedKey) }
    }

    var thinksRemaining: Int {
        max(0, Constants.maxFreeThinks - thinksUsed)
    }

    var thinkLimitReached: Bool {
        switch currentTier {
        case .free: return thinksUsed >= Constants.maxFreeThinks
        case .core: return coreLimitReached
        case .pro:  return false
        }
    }

    // MARK: - Monthly Think Counter

    var monthlyThinkCount: Int {
        get {
            let lastResetKey = "lastMonthlyReset"
            let countKey = "monthlyThinkCount"
            let calendar = Calendar.current
            let now = Date()
            if let lastReset = UserDefaults.standard.object(forKey: lastResetKey) as? Date {
                if !calendar.isDate(lastReset, equalTo: now, toGranularity: .month) {
                    UserDefaults.standard.set(0, forKey: countKey)
                    UserDefaults.standard.set(now, forKey: lastResetKey)
                    return 0
                }
            } else {
                UserDefaults.standard.set(now, forKey: lastResetKey)
                return 0
            }
            return UserDefaults.standard.integer(forKey: countKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "monthlyThinkCount")
        }
    }

    func incrementThinkCounters() {
        monthlyThinkCount += 1
        if currentTier == .core {
            coreThinksUsed += 1
        }
    }

    // MARK: - Chat

    var chatModelForCurrentTier: String {
        // Chat is always Haiku — only Pro users can chat
        return "claude-haiku-4-5-20251001"
    }

    var monthlyChatCount: Int {
        get {
            let countKey = "monthlyChatCount"
            let lastResetKey = "lastMonthlyChatReset"
            let calendar = Calendar.current
            let now = Date()
            if let lastReset = UserDefaults.standard.object(forKey: lastResetKey) as? Date {
                if !calendar.isDate(lastReset, equalTo: now, toGranularity: .month) {
                    UserDefaults.standard.set(0, forKey: countKey)
                    UserDefaults.standard.set(now, forKey: lastResetKey)
                    return 0
                }
            } else {
                UserDefaults.standard.set(now, forKey: lastResetKey)
                return 0
            }
            return UserDefaults.standard.integer(forKey: countKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "monthlyChatCount")
        }
    }

    func incrementMonthlyChatCount() {
        monthlyChatCount += 1
    }

    var shouldUseHaiku: Bool {
        #if DEBUG
        return forceHaikuMode
        #else
        return true
        #endif
    }

    #if DEBUG
    @Published var forceHaikuMode: Bool = false
    #endif

    // MARK: - Init
    init() {
        loadHistory()
    }

    // MARK: - Flow
    func submitQuestion(_ question: String) {
        guard !thinkLimitReached else {
            appState = .paywallRequired
            return
        }
        originalQuestion = question
        appState = .processingFirst

        currentTask = Task {
            do {
                let firstPass = try await APIClient.shared.firstPass(question: question, useHaiku: shouldUseHaiku)

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
                useHaiku: shouldUseHaiku
            )

            await MainActor.run {
                self.thinksUsed += 1
                self.incrementThinkCounters()
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
            thinkCount: 7,
            historyInsight: "Every think you've done involves someone else's expectations sitting inside your decision. Your parents. Your girlfriend. Your manager. You frame your choices around what they need first and what you need second. That pattern is consistent enough now that it's worth naming."
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

    // Clears think history and pattern memory only.
    // All counters (thinksUsed, coreThinksUsed, monthly counts) are intentionally
    // kept so tier enforcement can't be gamed by resetting memory.
    func resetBrainMemory() {
        // Clear in-memory array first
        thinkHistory = []

        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: Constants.thinkHistoryKey)
        UserDefaults.standard.removeObject(forKey: "patternData")

        // Reset pattern data in memory
        patternData = nil

        // Navigate home and notify views
        appState = .home
        objectWillChange.send()
    }
}
