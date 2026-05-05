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
    func firstPass(question: String) async throws -> FirstPassResponse {
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

        let body: [String: Any] = [
            "model": Constants.model,
            "max_tokens": 300,
            "system": Constants.firstPassSystemPrompt,
            "messages": messages
        ]

        let responseText = try await makeRequest(body: body)

        guard let data = responseText.data(using: .utf8) else {
            throw APIError.decodingError("Could not convert response to data")
        }

        do {
            return try JSONDecoder().decode(FirstPassResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - Call 2: Full Decision
    func secondPass(question: String, followUpAnswer: String = "", thinkHistory: [Think] = []) async throws -> DecisionResult {
        if Constants.useMockData {
            try await Task.sleep(nanoseconds: 1_500_000_000)
            return .mock
        }

        var userContent = question
        if !followUpAnswer.isEmpty {
            userContent += "\n\nAdditional context: \(followUpAnswer)"
        }

        if !thinkHistory.isEmpty {
            let historyContext = buildHistoryContext(from: thinkHistory)
            userContent += "\n\nPast thinks for pattern detection:\n\(historyContext)"
        }

        let messages: [[String: Any]] = [
            ["role": "user", "content": userContent]
        ]

        let body: [String: Any] = [
            "model": Constants.model,
            "max_tokens": 1500,
            "system": Constants.secondPassSystemPrompt,
            "messages": messages
        ]

        let responseText = try await makeRequest(body: body)
        let cleanedResponse = cleanJSON(responseText)

        guard let data = cleanedResponse.data(using: .utf8) else {
            throw APIError.decodingError("Could not convert response to data")
        }

        do {
            return try JSONDecoder().decode(DecisionResult.self, from: data)
        } catch {
            throw APIError.decodingError("JSON decode failed: \(error.localizedDescription)\n\nRaw: \(responseText)")
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
    private func cleanJSON(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") { cleaned = String(cleaned.dropFirst(7)) }
        if cleaned.hasPrefix("```") { cleaned = String(cleaned.dropFirst(3)) }
        if cleaned.hasSuffix("```") { cleaned = String(cleaned.dropLast(3)) }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func buildHistoryContext(from thinks: [Think]) -> String {
        let recent = thinks.suffix(5)
        return recent.map { think in
            "- \(think.originalQuestion) → \(think.result.verdict) (\(think.result.confidence)% confidence)"
        }.joined(separator: "\n")
    }
}
