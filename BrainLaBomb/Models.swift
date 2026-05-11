import Foundation

// MARK: - Mode
enum DecisionMode: String, Codable {
    case decision = "DECISION"
    case direction = "DIRECTION"
    case emotional = "EMOTIONAL"
}

// MARK: - First Pass
struct FirstPassResponse: Codable {
    let needsQuestion: Bool
    let question: String
    let mode: DecisionMode
}

// MARK: - Outcome Row
struct OutcomeRow: Codable, Identifiable {
    var id: UUID = UUID()
    let percentage: Int
    let title: String
    let explanation: String

    enum CodingKeys: String, CodingKey {
        case percentage, title, explanation
    }
}

// MARK: - Decision Archetype
struct DecisionArchetype: Codable {
    let name: String
    let description: String
    let percentage: Int
}

// MARK: - Decision Report
struct DecisionReport: Codable {
    // reasoning is [String] so StoriesView's .joined(separator:) call keeps working;
    // the API returns a single string which we wrap in an array during decoding.
    let reasoning: [String]
    let whyPoints: [String]
    let tradeoffs: [String]
    let majorityOutcomes: [OutcomeRow]
    let minorityOutcomes: [OutcomeRow]
    let patternNote: String
    let needsAmbientQuestion: Bool
    let ambientQuestion: String
    let whatYoureNotSaying: String
    let whatUsuallyHelps: String
    // legacy display fields — not returned by the new API, filled with defaults
    let majorityLabel: String
    let topic: String
}

// MARK: - Decision Result
struct DecisionResult: Codable, Identifiable {
    var id: UUID = UUID()
    let verdict: String
    let confidence: Int
    let simulationCount: Int
    let mode: DecisionMode
    let archetype: DecisionArchetype
    let report: DecisionReport

    // Legacy computed accessors used by CardBackView / StoriesView
    var why: [String]       { report.whyPoints }
    var tradeoffs: [String] { report.tradeoffs }
    var isPositive: Bool    { confidence >= 50 }

    // MARK: Flat-JSON init (API response has all fields at the root level)
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        verdict         = try c.decode(String.self,       forKey: .verdict)
        confidence      = try c.decode(Int.self,          forKey: .confidence)
        simulationCount = try c.decode(Int.self,          forKey: .simulationCount)
        mode            = try c.decode(DecisionMode.self, forKey: .mode)

        let reasoningStr    = try c.decode(String.self,     forKey: .reasoning)
        let whyPoints       = try c.decode([String].self,   forKey: .whyPoints)
        let tradeoffs       = try c.decode([String].self,   forKey: .tradeoffs)
        let majorityOutcomes = try c.decode([OutcomeRow].self, forKey: .majorityOutcomes)
        let minorityOutcomes = try c.decode([OutcomeRow].self, forKey: .minorityOutcomes)
        let patternNote     = try c.decode(String.self,     forKey: .patternNote)
        let needsAmbQ       = try c.decode(Bool.self,       forKey: .needsAmbientQuestion)
        let ambQ            = try c.decode(String.self,     forKey: .ambientQuestion)
        let whatYoureNotSaying = (try? c.decode(String.self, forKey: .whatYoureNotSaying)) ?? ""
        let whatUsuallyHelps   = (try? c.decode(String.self, forKey: .whatUsuallyHelps))   ?? ""
        archetype = (try? c.decode(DecisionArchetype.self, forKey: .archetype))
            ?? DecisionArchetype(name: "The Thinker", description: "you came here for a reason.", percentage: 21)

        report = DecisionReport(
            reasoning:            [reasoningStr],
            whyPoints:            whyPoints,
            tradeoffs:            tradeoffs,
            majorityOutcomes:     majorityOutcomes,
            minorityOutcomes:     minorityOutcomes,
            patternNote:          patternNote,
            needsAmbientQuestion: needsAmbQ,
            ambientQuestion:      ambQ,
            whatYoureNotSaying:   whatYoureNotSaying,
            whatUsuallyHelps:     whatUsuallyHelps,
            majorityLabel:        "made that call",
            topic:                "decisions like this"
        )
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(verdict,                       forKey: .verdict)
        try c.encode(confidence,                    forKey: .confidence)
        try c.encode(simulationCount,               forKey: .simulationCount)
        try c.encode(mode,                          forKey: .mode)
        try c.encode(report.reasoning.joined(separator: " "), forKey: .reasoning)
        try c.encode(report.whyPoints,              forKey: .whyPoints)
        try c.encode(report.tradeoffs,              forKey: .tradeoffs)
        try c.encode(report.majorityOutcomes,       forKey: .majorityOutcomes)
        try c.encode(report.minorityOutcomes,       forKey: .minorityOutcomes)
        try c.encode(report.patternNote,            forKey: .patternNote)
        try c.encode(report.needsAmbientQuestion,   forKey: .needsAmbientQuestion)
        try c.encode(report.ambientQuestion,        forKey: .ambientQuestion)
        try c.encode(report.whatYoureNotSaying,     forKey: .whatYoureNotSaying)
        try c.encode(report.whatUsuallyHelps,       forKey: .whatUsuallyHelps)
        try c.encode(archetype,                     forKey: .archetype)
    }

    enum CodingKeys: String, CodingKey {
        case verdict, confidence, simulationCount, mode
        case reasoning, whyPoints, tradeoffs
        case majorityOutcomes, minorityOutcomes
        case patternNote, needsAmbientQuestion, ambientQuestion
        case whatYoureNotSaying, whatUsuallyHelps
        case archetype
    }
}

// MARK: - Pattern Identity
struct PatternIdentity: Codable {
    let name: String
    let description: String
    let percentage: Int
    let insight: String
}

struct PatternData: Codable {
    let identity: PatternIdentity
    let generatedAt: Date
    let thinkCount: Int
}

// MARK: - Think (History)
struct Think: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let originalQuestion: String
    let followUpQuestion: String
    let followUpAnswer: String
    let result: DecisionResult
    var chatMessages: [ChatBubble]

    init(originalQuestion: String, followUpQuestion: String = "", followUpAnswer: String = "", result: DecisionResult) {
        self.id = UUID()
        self.timestamp = Date()
        self.originalQuestion = originalQuestion
        self.followUpQuestion = followUpQuestion
        self.followUpAnswer = followUpAnswer
        self.result = result
        self.chatMessages = []
    }
}

// MARK: - Chat Message (for future chat feature)
struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let content: String
    let isUser: Bool
    let linkedThinkID: UUID?

    init(content: String, isUser: Bool, linkedThinkID: UUID? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.content = content
        self.isUser = isUser
        self.linkedThinkID = linkedThinkID
    }
}

// MARK: - Mock Data
extension DecisionResult {
    static let mock = DecisionResult.mockBuild()

    private static func mockBuild() -> DecisionResult {
        let json = """
        {
          "verdict": "don't take this job",
          "confidence": 87,
          "simulationCount": 1247,
          "mode": "DECISION",
          "reasoning": "Night shifts rewire your sleep permanently over time. No holidays means your body never fully recovers. The money feels worth it now. Six months in, it won't. Your nervous system knows the difference between a hard season and a bad deal.",
          "whyPoints": ["protects your long-term health", "keeps better options open", "your energy is your real asset"],
          "tradeoffs": ["short-term income loss", "transition period uncertainty"],
          "majorityOutcomes": [
            {"percentage": 52, "title": "Burnout", "explanation": "Chronic fatigue sets in within 3-6 months"},
            {"percentage": 23, "title": "Relationship strain", "explanation": "No time or energy for the people around you"},
            {"percentage": 12, "title": "Stuck", "explanation": "Low learning, no leverage, regret builds slowly"}
          ],
          "minorityOutcomes": [
            {"percentage": 7, "title": "Financial pressure", "explanation": "No better option existed at the time"},
            {"percentage": 4, "title": "Short stint", "explanation": "Planned exit within 3 months worked for some"},
            {"percentage": 2, "title": "Adapted", "explanation": "Lifestyle adjusted but at significant personal cost"}
          ],
          "patternNote": "",
          "whatYoureNotSaying": "You're not just missing her. You're missing the version of yourself that existed when she was around. That's harder to admit because it means this isn't just about her.",
          "whatUsuallyHelps": "Most people in this spot need to stop performing okay before they can actually get there. Give yourself one honest conversation — with yourself first, not her.",
          "needsAmbientQuestion": false,
          "ambientQuestion": "",
          "archetype": {
            "name": "The Overthinker",
            "description": "you see every angle. landing is the hard part.",
            "percentage": 24
          }
        }
        """
        let data = json.data(using: .utf8)!
        return try! JSONDecoder().decode(DecisionResult.self, from: data)
    }
}
