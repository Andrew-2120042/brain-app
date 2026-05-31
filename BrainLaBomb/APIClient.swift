import Foundation

enum APIError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case decodingError(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:       return "Invalid response from server"
        case .httpError(let code):   return "Server error \(code)"
        case .decodingError(let msg): return "Could not read response: \(msg)"
        case .networkError(let msg): return "Network error: \(msg)"
        }
    }
}

struct APIClient {

    static let shared = APIClient()
    private init() {}

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        config.shouldUseExtendedBackgroundIdleMode = true
        return URLSession(configuration: config)
    }()

    // MARK: - Call 1: Classification
    func firstPass(question: String, useHaiku: Bool = false, forceCorrupt: Bool = false) async throws -> FirstPassResponse {
        if Constants.useMockData {
            try await Task.sleep(nanoseconds: 800_000_000)
            return FirstPassResponse(
                needsQuestion: true,
                question: "What's making this feel hard to decide right now?",
                mode: .decision
            )
        }

        let messages: [[String: Any]] = [
            ["role": "user", "content": question]
        ]

        let modelToUse = useHaiku ? "claude-haiku-4-5-20251001" : Constants.model

        let body: [String: Any] = [
            "model": modelToUse,
            "max_tokens": 300,
            "system": [
                [
                    "type": "text",
                    "text": Constants.firstPassSystemPrompt,
                    "cache_control": ["type": "ephemeral"]
                ]
            ],
            "messages": messages
        ]

        let responseText = try await makeRequest(body: body)

        #if DEBUG
        let responseToProcess: String
        if forceCorrupt {
            responseToProcess = "This is intentionally corrupted plain text to test the Sonnet fallback mechanism."
        } else {
            responseToProcess = responseText
        }
        #else
        let responseToProcess = responseText
        #endif

        // SONNET FALLBACK LOGIC:
        // extractJSONDictionary returns nil ONLY when the model returned something with
        // zero valid JSON anywhere — pure plain text, empty response, completely malformed.
        // This is NOT triggered by:
        //   - Valid JSON with missing fields (fault tolerant decoder handles that)
        //   - Valid JSON that fails Codable decode (handled downstream)
        //   - Network errors or timeouts (those throw before reaching here)
        // Sonnet ONLY runs when there is literally no JSON object to extract.
        guard let dict = extractJSONDictionary(from: responseToProcess) else {

            #if DEBUG
            print("⚠️ [FALLBACK] firstPass: Haiku returned non-JSON. Triggering Sonnet fallback.")
            print("⚠️ [FALLBACK] Raw Haiku response: \(responseToProcess)")
            #endif

            // Build Sonnet fallback request.
            // System prompt stays as firstPassSystemPrompt — same for both models.
            // Only the model string changes.
            var sonnetBody = body
            sonnetBody["model"] = Constants.model // claude-sonnet-4-20250514

            let sonnetResponse = try await makeRequest(body: sonnetBody)

            guard let sonnetDict = extractJSONDictionary(from: sonnetResponse) else {
                throw APIError.decodingError("Both Haiku and Sonnet returned non-JSON.\n\nHaiku raw:\n\(responseToProcess)\n\nSonnet raw:\n\(sonnetResponse)")
            }

            // Sonnet succeeded. Build response from Sonnet dict.
            let needsQuestion = (sonnetDict["needsQuestion"] as? Bool) ?? false
            let questionText = (sonnetDict["question"] as? String) ?? ""
            let modeRaw = (sonnetDict["mode"] as? String) ?? "EMOTIONAL"
            let mode = parseMode(modeRaw)
            return FirstPassResponse(needsQuestion: needsQuestion, question: questionText, mode: mode)
        }

        // Haiku succeeded. Sonnet never ran. Build response from Haiku dict.
        let needsQuestion = (dict["needsQuestion"] as? Bool) ?? false
        let questionText = (dict["question"] as? String) ?? ""
        let modeRaw = (dict["mode"] as? String) ?? "EMOTIONAL"
        let mode = parseMode(modeRaw)

        return FirstPassResponse(
            needsQuestion: needsQuestion,
            question: questionText,
            mode: mode
        )
    }

    // MARK: - Call 2: Full Decision
    func secondPass(question: String, followUpAnswer: String = "", useHaiku: Bool = false, forceCorrupt: Bool = false) async throws -> DecisionResult {
        if Constants.useMockData {
            try await Task.sleep(nanoseconds: 1_500_000_000)
            return .mock
        }

        var userContent = question
        if !followUpAnswer.isEmpty {
            userContent += "\n\nAdditional context: \(followUpAnswer)"
        }

        let messages: [[String: Any]] = [
            ["role": "user", "content": userContent]
        ]

        let modelToUse = useHaiku ? "claude-haiku-4-5-20251001" : Constants.model

        let systemPrompt = useHaiku
            ? Constants.haikuSystemPrompt
            : Constants.secondPassSystemPrompt + Constants.anchoringRules

        let body: [String: Any] = [
            "model": modelToUse,
            "max_tokens": 1500,
            "system": [
                [
                    "type": "text",
                    "text": systemPrompt,
                    "cache_control": ["type": "ephemeral"]
                ]
            ],
            "messages": messages
        ]

        let responseText = try await makeRequest(body: body)

        #if DEBUG
        let responseToProcess: String
        if forceCorrupt {
            responseToProcess = "This is intentionally corrupted plain text to test the Sonnet fallback mechanism."
        } else {
            responseToProcess = responseText
        }
        #else
        let responseToProcess = responseText
        #endif

        // SONNET FALLBACK LOGIC:
        // Same strict condition as firstPass — only triggers when extractJSONDictionary
        // returns nil. This means the model returned pure plain text or completely malformed
        // output with zero valid JSON anywhere.
        //
        // IMPORTANT — system prompt swap:
        // When falling back to Sonnet, we must also swap the system prompt.
        // Haiku uses haikuSystemPrompt. Sonnet uses secondPassSystemPrompt + anchoringRules.
        // These are different prompts optimized for each model.
        // Do NOT use haikuSystemPrompt with Sonnet — it will produce worse results.
        // Do NOT use secondPassSystemPrompt with Haiku — the dedicated Haiku prompt is better.
        // This swap is intentional and must be preserved if this code is ever modified.
        if let dict = extractJSONDictionary(from: responseToProcess),
           let data = try? JSONSerialization.data(withJSONObject: dict) {

            // Haiku succeeded. Sonnet never ran.

            // Defensive: Haiku sometimes returns the firstPass-shaped triage JSON
            // ({needsQuestion, question, mode}) on the secondPass call instead of the
            // full decision JSON. Detect that and synthesize a fallback DecisionResult
            // so the user sees something useful rather than a cryptic decode error.
            if dict["verdict"] == nil && dict["needsQuestion"] != nil {
                return fallbackDecisionResult(
                    question: question,
                    triageDict: dict,
                    modelUsed: modelToUse
                )
            }

            do {
                var result = try JSONDecoder().decode(DecisionResult.self, from: data)
                result.modelUsed = modelToUse // stamps "claude-haiku-4-5-20251001"
                return result
            } catch {
                throw APIError.decodingError("Haiku JSON decode failed: \(error.localizedDescription)\n\nRaw:\n\(responseToProcess)")
            }

        } else {

            // Haiku returned non-JSON. Silent Sonnet fallback.
            #if DEBUG
            print("⚠️ [FALLBACK] secondPass: Haiku returned non-JSON. Triggering Sonnet fallback.")
            print("⚠️ [FALLBACK] Raw Haiku response: \(responseToProcess)")
            #endif

            // Build Sonnet fallback request.
            // CRITICAL: swap both model AND system prompt.
            // Sonnet needs secondPassSystemPrompt + anchoringRules, not haikuSystemPrompt.
            // See comment above for why this swap is necessary and intentional.
            var sonnetBody = body
            sonnetBody["model"] = Constants.model // claude-sonnet-4-20250514
            sonnetBody["system"] = [
                [
                    "type": "text",
                    "text": Constants.secondPassSystemPrompt + Constants.anchoringRules,
                    "cache_control": ["type": "ephemeral"]
                ]
            ]

            let sonnetResponse = try await makeRequest(body: sonnetBody)

            guard let sonnetDict = extractJSONDictionary(from: sonnetResponse),
                  let sonnetData = try? JSONSerialization.data(withJSONObject: sonnetDict) else {
                throw APIError.decodingError("Both Haiku and Sonnet returned non-JSON.\n\nSonnet raw:\n\(sonnetResponse)")
            }

            // Sonnet succeeded. Decode Sonnet response.
            do {
                var result = try JSONDecoder().decode(DecisionResult.self, from: sonnetData)
                result.modelUsed = Constants.model // stamps "claude-sonnet-4-20250514" — shows SONNET badge in debug
                return result
            } catch {
                throw APIError.decodingError("Sonnet fallback decode failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Call 3: Pattern Analysis
    func analyzePattern(thinkHistory: [Think]) async throws -> PatternData? {
        guard thinkHistory.count >= 5 else { return nil }

        let recentThinks = Array(thinkHistory.suffix(5))
        let historyContext = recentThinks.map { think in
            """
            Situation: \(think.originalQuestion)
            Verdict: \(think.result.verdict)
            Confidence: \(think.result.confidence)%
            Archetype: \(think.result.archetype.name)
            Archetype description: \(think.result.archetype.description)
            Mode: \(think.result.mode.rawValue)
            """
        }.joined(separator: "\n---\n")

        let userMessage = """
        Here are this person's most recent 5 thinks:

        \(historyContext)

        Analyze their pattern identity based on these recent thinks.
        """

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 700,
            "system": [
                [
                    "type": "text",
                    "text": Constants.patternAnalysisPrompt,
                    "cache_control": ["type": "ephemeral"]
                ]
            ],
            "messages": [["role": "user", "content": userMessage]]
        ]

        let responseText = try await makeRequest(body: body)

        guard let dict = extractJSONDictionary(from: responseText),
              let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }

        struct PatternResponse: Codable {
            let needsMoreData: Bool
            let patternIdentity: PatternIdentity?
            let historyInsight: String?
        }

        do {
            let response = try JSONDecoder().decode(PatternResponse.self, from: data)
            guard !response.needsMoreData, let identity = response.patternIdentity else { return nil }
            return PatternData(
                identity: identity,
                generatedAt: Date(),
                thinkCount: thinkHistory.count,
                historyInsight: response.historyInsight ?? ""
            )
        } catch {
            #if DEBUG
            print("Pattern analysis decode failed: \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    // MARK: - Pattern Reveal
    func generatePatternReveal(
        frequency: String,
        blockers: [String],
        duration: String,
        currentState: String
    ) async throws -> String {
        let blockersText = blockers.isEmpty ? "unknown" : blockers.joined(separator: " and ")
        let prompt = """
        You are writing a pattern reveal for a decision-making app onboarding.

        The user answered:
        - How often they face decisions: \(frequency)
        - What stops them trusting instincts: \(blockersText)
        - How long sitting with decision: \(duration)
        - Where they are right now: \(currentState)

        Write exactly 4 lines. No more. No fewer.

        Line 1: one trait observation using their frequency answer. Under 10 words. Start with "you".
        Line 2: one trait observation using their blocker or duration answer. Under 10 words. Start with "you".
        Line 3: one insight connecting both traits into a pattern they haven't named. Under 15 words. Do not start with "you".
        Line 4: one reframe. Under 10 words. Does not start with "you". Relieves shame without dismissing reality.

        Total word count across all 4 lines must be under 45 words.
        No blank lines between lines.
        No bullet points. No numbering. No labels.
        Return only the 4 lines. Nothing else. No quotes. No explanation.
        """

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 80,
            "system": "You write precise personalised psychological pattern reveals for a decision-making app. Follow the structure given exactly. Never add extra content. Never use therapeutic language. Never use the word 'however'. Sound like a perceptive friend who sees patterns clearly.",
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        return try await makeRequest(body: body)
    }

    // MARK: - Onboarding Reflection
    func generateOnboardingReflection(selections: [String]) async throws -> String {
        let selectionText = selections.joined(separator: " and ")
        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 60,
            "system": "You write one short sharp reflection for a decision-making app onboarding. Maximum 15 words. Second person. Period at end only. Sounds like a perceptive friend not a therapist. Return only the reflection. Nothing else. No quotes.",
            "messages": [
                ["role": "user", "content": "The user struggles with: \(selectionText). Write one reflection."]
            ]
        ]
        return try await makeRequest(body: body)
    }

    // MARK: - Core Request
    private func makeRequest(body: [String: Any]) async throws -> String {
        guard let url = URL(string: Constants.baseURL) else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Constants.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Constants.anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("prompt-caching-2024-07-31", forHTTPHeaderField: "anthropic-beta")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw APIError.networkError("no internet connection. check your connection and try again.")
            case .timedOut:
                throw APIError.networkError("the brain took too long to respond. try again in a moment.")
            case .cannotConnectToHost, .cannotFindHost:
                throw APIError.networkError("can't reach the brain right now. try again in a moment.")
            default:
                throw APIError.networkError("something interrupted the brain. try again in a moment.")
            }
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            switch httpResponse.statusCode {
            case 429:
                throw APIError.networkError("the brain needs a breather. wait a moment and try again.")
            case 529:
                throw APIError.networkError("the brain is overwhelmed right now. try again in a moment.")
            case 500:
                throw APIError.networkError("the brain hit a wall. this is on us. try again in a moment.")
            case 502, 503, 504:
                throw APIError.networkError("the brain is unreachable right now. try again in a moment.")
            case 401, 403:
                throw APIError.networkError("the brain lost its connection. restart the app and try again.")
            default:
                throw APIError.networkError("something interrupted the brain. try again in a moment.")
            }
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            throw APIError.invalidResponse
        }

        return text
    }

    // MARK: - Helpers

    // Walks the text and pulls out the first balanced {...} block, then parses it.
    // Tolerates: markdown fences, preamble/postamble text, multiple JSON objects,
    // braces inside strings, escaped quotes. Returns nil only if no valid JSON
    // dictionary exists anywhere in the input.
    private func extractJSONDictionary(from text: String) -> [String: Any]? {
        // Fast path — try parsing the whole thing directly (with light trimming).
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let data = trimmed.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return obj
        }

        // Scan for the first balanced JSON object, tracking string state to avoid
        // mistaking braces inside string literals for structural braces.
        let chars = Array(text)
        var startIndex: Int? = nil
        var depth = 0
        var inString = false
        var escape = false

        for i in 0..<chars.count {
            let c = chars[i]

            if escape { escape = false; continue }
            if inString {
                if c == "\\" { escape = true }
                else if c == "\"" { inString = false }
                continue
            }
            if c == "\"" { inString = true; continue }

            if c == "{" {
                if startIndex == nil { startIndex = i }
                depth += 1
            } else if c == "}" {
                depth -= 1
                if depth == 0, let start = startIndex {
                    let candidate = String(chars[start...i])
                    if let data = candidate.data(using: .utf8),
                       let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        return obj
                    }
                    // Not parseable — keep looking for another object.
                    startIndex = nil
                }
            }
        }
        return nil
    }

    private func parseMode(_ raw: String) -> DecisionMode {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return DecisionMode(rawValue: normalized) ?? .emotional
    }

    // Used when secondPass receives a triage-shaped response (Haiku regression).
    // Builds a minimal-but-valid DecisionResult that lets the UI render gracefully
    // instead of crashing into the error screen. The reasoning carries the question
    // back so the user can see why the model felt it couldn't simulate fully.
    private func fallbackDecisionResult(
        question: String,
        triageDict: [String: Any],
        modelUsed: String
    ) -> DecisionResult {
        let modeRaw = (triageDict["mode"] as? String) ?? "EMOTIONAL"
        let mode = parseMode(modeRaw)
        let askedQuestion = (triageDict["question"] as? String) ?? ""

        let reasoning = askedQuestion.isEmpty
            ? "sit with this for a moment. nothing here demands an instant answer. the next move usually shows itself once the noise quiets down."
            : "the brain wanted to ask: \(askedQuestion). try again with a little more context and it can give you a real read."

        let fallbackJSON: [String: Any] = [
            "verdict": "not enough to simulate yet.",
            "confidence": 0,
            "simulationCount": 0,
            "mode": mode.rawValue,
            "reasoning": reasoning,
            "whyPoints": [],
            "tradeoffs": [],
            "majorityOutcomes": [],
            "minorityOutcomes": [],
            "patternNote": "",
            "needsAmbientQuestion": false,
            "ambientQuestion": "",
            "whatYoureNotSaying": "",
            "whatUsuallyHelps": "",
            "archetype": [
                "name": "The Thinker",
                "description": "you came here for a reason.",
                "percentage": 21
            ]
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: fallbackJSON),
              var result = try? JSONDecoder().decode(DecisionResult.self, from: data) else {
            // Last-resort: return the mock so the UI never breaks.
            var r = DecisionResult.mock
            r.modelUsed = modelUsed
            return r
        }
        result.modelUsed = modelUsed
        return result
    }

    private func buildHistoryContext(from thinks: [Think]) -> String {
        let recent = thinks.suffix(5)
        return recent.map { think in
            "- \(think.originalQuestion) → \(think.result.verdict) (\(think.result.confidence)% confidence)"
        }.joined(separator: "\n")
    }
}
