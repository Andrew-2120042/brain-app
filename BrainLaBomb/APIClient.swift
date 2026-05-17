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

    // MARK: - Call 1: Classification
    func firstPass(question: String, useHaiku: Bool = false) async throws -> FirstPassResponse {
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
            "system": Constants.firstPassSystemPrompt,
            "messages": messages
        ]

        let responseText = try await makeRequest(body: body)

        // Bulletproof extraction — always pull out a usable JSON object dictionary
        // regardless of code fences, preamble, or extra text around it.
        guard let dict = extractJSONDictionary(from: responseText) else {
            throw APIError.decodingError("Could not find JSON object in response\n\nRaw:\n\(responseText)")
        }

        // Manually build FirstPassResponse from the dictionary with safe defaults.
        // This avoids Codable strictness — missing or oddly-cased fields won't crash the flow.
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
    func secondPass(question: String, followUpAnswer: String = "", useHaiku: Bool = false) async throws -> DecisionResult {
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
            "system": systemPrompt,
            "messages": messages
        ]

        let responseText = try await makeRequest(body: body)

        // Pull out the JSON object from anywhere in the response, then re-serialize
        // to clean canonical JSON before decoding — bypasses any markdown fences,
        // preamble text, or whitespace the model might add.
        guard let dict = extractJSONDictionary(from: responseText),
              let data = try? JSONSerialization.data(withJSONObject: dict) else {
            throw APIError.decodingError("Could not find JSON object in response\n\nRaw:\n\(responseText)")
        }

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
            result.modelUsed = modelToUse
            return result
        } catch {
            throw APIError.decodingError("JSON decode failed: \(error.localizedDescription)\n\nRaw: \(responseText)")
        }
    }

    // MARK: - Call 3: Pattern Analysis
    func analyzePattern(thinkHistory: [Think]) async throws -> PatternData? {
        guard thinkHistory.count >= 5 else { return nil }

        let historyContext = thinkHistory.map { think in
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
        Here is this person's think history (\(thinkHistory.count) thinks total):

        \(historyContext)

        Analyze their pattern identity based on this history.
        """

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 700,
            "system": Constants.patternAnalysisPrompt,
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
        request.timeoutInterval = 30

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
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
