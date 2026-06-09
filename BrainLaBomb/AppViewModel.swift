import Foundation
import Combine
import UIKit
import StoreKit
import RevenueCat
import PostHog

enum AppState {
    case home
    case input
    case processingFirst
    case question(String)
    case processingSecond
    case result(DecisionResult)
    case error(String)

}

enum AppTier {
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
    private var savedFollowUpAnswer: String = ""
    @Published var lastErrorWasOverload: Bool = false

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

    // TODO: replace with RevenueCat check when integrated
    @Published var debugTier: AppTier = .core

    #if DEBUG
    @Published var hideDebugUI: Bool = false
    #endif

    @Published var purchasedTier: AppTier = .core
    @Published var isLoadingPurchase: Bool = false
    @Published var currentOffering: Offering? = nil

    var currentTier: AppTier {
        #if DEBUG
        return debugTier
        #else
        return purchasedTier
        #endif
    }

    var coreThinksUsed: Int {
        get { UserDefaults.standard.integer(forKey: "coreThinksUsed") }
        set { UserDefaults.standard.set(newValue, forKey: "coreThinksUsed") }
    }

    var coreThinkLimit: Int { 300 }
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

    var thinkLimitReached: Bool {
        switch currentTier {
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

    var shouldUseHaiku: Bool { return true }

    // MARK: - RevenueCat
    func checkSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            await MainActor.run {
                if customerInfo.entitlements["pro"]?.isActive == true {
                    self.purchasedTier = .pro
                    PostHogSDK.shared.capture("subscription_activated", properties: ["tier": "pro"])
                } else if customerInfo.entitlements["core"]?.isActive == true {
                    self.purchasedTier = .core
                    PostHogSDK.shared.capture("subscription_activated", properties: ["tier": "core"])
                } else {
                    self.purchasedTier = .core
                }
                PostHogSDK.shared.capture("session_started", properties: [
                    "tier": self.purchasedTier == .pro ? "pro" : "core",
                    "think_count": self.thinksUsed
                ])
            }
        } catch {}
    }

    func fetchOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            await MainActor.run {
                self.currentOffering = offerings.current
            }
        } catch {}
    }

    func purchase(package: Package) async {
        await MainActor.run { isLoadingPurchase = true }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            await MainActor.run {
                isLoadingPurchase = false
                if result.customerInfo.entitlements["pro"]?.isActive == true {
                    self.purchasedTier = .pro
                } else if result.customerInfo.entitlements["core"]?.isActive == true {
                    self.purchasedTier = .core
                }
            }
        } catch {
            await MainActor.run { isLoadingPurchase = false }
        }
    }

    func restorePurchases() async {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            await MainActor.run {
                if customerInfo.entitlements["pro"]?.isActive == true {
                    self.purchasedTier = .pro
                } else if customerInfo.entitlements["core"]?.isActive == true {
                    self.purchasedTier = .core
                }
            }
        } catch {}
    }

    // MARK: - Init
    init() {
        loadHistory()
    }

    // MARK: - Flow
    func submitQuestion(_ question: String) {
        let sanitizedQuestion = sanitizeInput(question)
        savedFollowUpAnswer = ""
        originalQuestion = sanitizedQuestion
        appState = .processingFirst

        // TODO: RENAME — replace with final app name before App Store submission
        let bgTask = UIApplication.shared.beginBackgroundTask(withName: "bracket.think", expirationHandler: nil)

        currentTask = Task {
            do {
                let firstPass = try await APIClient.shared.firstPass(question: sanitizedQuestion, useHaiku: shouldUseHaiku)

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
                    let msg = error.localizedDescription
                    self.lastErrorWasOverload = msg.contains("breather") || msg.contains("overwhelmed")
                    #if DEBUG
                    self.appState = .error(msg)
                    #else
                    self.appState = .error(self.extractFriendlyMessage(msg))
                    #endif
                }
            }

            await MainActor.run {
                UIApplication.shared.endBackgroundTask(bgTask)
            }
        }
    }

    func submitFollowUp(answer: String) {
        followUpAnswer = answer
        savedFollowUpAnswer = answer
        appState = .processingSecond

        // TODO: RENAME — replace with final app name before App Store submission
        let bgTask = UIApplication.shared.beginBackgroundTask(withName: "bracket.think", expirationHandler: nil)

        currentTask = Task {
            await runSecondPass(answer: answer)

            await MainActor.run {
                UIApplication.shared.endBackgroundTask(bgTask)
            }
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
                UserDefaults.standard.set(
                    UserDefaults.standard.integer(forKey: "totalThinkCount") + 1,
                    forKey: "totalThinkCount"
                )
                self.requestReviewIfAppropriate()
                PostHogSDK.shared.capture("think_submitted", properties: [
                    "tier": self.currentTier == .pro ? "pro" : "core",
                    "think_count": self.thinksUsed,
                    "hour_of_day": Calendar.current.component(.hour, from: Date())
                ])
            }

        } catch {
            await MainActor.run {
                let msg = error.localizedDescription
                self.lastErrorWasOverload = msg.contains("breather") || msg.contains("overwhelmed")
                #if DEBUG
                self.appState = .error(msg)
                #else
                self.appState = .error(self.extractFriendlyMessage(msg))
                #endif
            }
        }
    }

    private func extractFriendlyMessage(_ message: String) -> String {
        let technicalPrefixes = [
            "JSON decode", "Could not", "Server error", "URLError",
            "The request", "Haiku", "Sonnet", "Both Haiku", "Invalid response"
        ]
        for prefix in technicalPrefixes {
            if message.hasPrefix(prefix) {
                return "something went wrong. try again in a moment."
            }
        }
        return message
    }

    private func sanitizeInput(_ input: String) -> String {
        let maxLength = 1000
        var sanitized = input.trimmingCharacters(in: .whitespacesAndNewlines)

        if sanitized.count > maxLength {
            sanitized = String(sanitized.prefix(maxLength))
        }

        sanitized = sanitized.filter { !$0.isNewline || $0 == "\n" }
        sanitized = sanitized.replacingOccurrences(of: "\0", with: "")

        return sanitized
    }

    func reset() {
        currentTask?.cancel()
        currentTask = nil
        originalQuestion = ""
        followUpQuestion = ""
        followUpAnswer = ""
        savedFollowUpAnswer = ""
        lastErrorWasOverload = false
        appState = .home
    }

    func retry() {
        guard !originalQuestion.isEmpty else {
            appState = .home
            return
        }

        let savedAnswer = savedFollowUpAnswer
        let isOverload = lastErrorWasOverload
        lastErrorWasOverload = false

        if !savedAnswer.isEmpty {
            // Error happened in secondPass — jump straight to secondPass with saved answer.
            // User does not have to answer the follow-up question again.
            currentTask?.cancel()
            appState = .processingSecond
            currentTask = Task {
                if isOverload {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                }
                await self.runSecondPass(answer: savedAnswer)
            }
        } else {
            // Error happened in firstPass — restart full flow from the beginning.
            if isOverload {
                currentTask?.cancel()
                appState = .processingFirst
                currentTask = Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await MainActor.run { self.submitQuestion(self.originalQuestion) }
                }
            } else {
                submitQuestion(originalQuestion)
            }
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

        // Run pattern analysis after every think once 5 exist
        // Uses rolling last 5 thinks as context — fresh pattern and historyInsight every think
        if thinkHistory.count >= 5 {
            Task { await runPatternAnalysis() }
        }
    }

    private func runPatternAnalysis() async {
        guard !Constants.useMockData else { return }
        do {
            if let newPattern = try await APIClient.shared.analyzePattern(thinkHistory: thinkHistory) {
                await MainActor.run { patternData = newPattern }
            }
        } catch {}
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
    func requestReviewIfAppropriate() {
        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
        #else
        let thinkCount = UserDefaults.standard.integer(forKey: "totalThinkCount")
        let hasReviewed = UserDefaults.standard.bool(forKey: "hasRequestedReview")
        guard thinkCount >= 3 && !hasReviewed else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
                UserDefaults.standard.set(true, forKey: "hasRequestedReview")
            }
        }
        #endif
    }

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
