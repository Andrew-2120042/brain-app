import Foundation

struct FirstPassResponse {
    let needsQuestion:    Bool
    let followUpQuestion: String?
}

struct OutcomeRow: Identifiable {
    let id = UUID()
    let title: String
    let explanation: String
    let percentage: Int
}

struct DecisionReport {
    let reasoning: [String]
    let majorityLabel: String           // e.g. "took it", "had the talk"
    let majorityOutcomes: [OutcomeRow]
    let minorityOutcomes: [OutcomeRow]
    let topic: String                   // e.g. "career moves like this"
}

struct DecisionResult: Identifiable {
    let id = UUID()
    let verdict: String
    let confidence: Int
    let isPositive: Bool
    let why: [String]
    let tradeoffs: [String]
    let report: DecisionReport
}
