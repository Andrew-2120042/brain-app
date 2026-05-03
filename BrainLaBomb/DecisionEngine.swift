import Foundation

enum DecisionEngine {

    static func firstPass(question: String) -> FirstPassResponse {
        let q = question.lowercased()
        let hasContext = q.contains("because") || q.contains("but") ||
                         q.contains("however") || q.contains("since") ||
                         q.contains("already") || q.count > 80
        if hasContext {
            return FirstPassResponse(needsQuestion: false, followUpQuestion: nil)
        }
        let followUps: [String] = [
            "What's making this feel hard to decide right now?",
            "What would staying the same actually cost you?",
            "What does the version of you that made the right call look like in a year?",
            "What are you most afraid of getting wrong here?",
            "Who else does this decision affect, and how?"
        ]
        let q2 = followUps[abs(question.hashValue) % followUps.count]
        return FirstPassResponse(needsQuestion: true, followUpQuestion: q2)
    }

    static func decide(question: String) -> DecisionResult {
        let q = question.lowercased()
        if q.contains("job") || q.contains("offer") || q.contains("career") || q.contains("work") {
            return career(q)
        }
        if q.contains("relationship") || q.contains("partner") || q.contains("dating") || q.contains("love") || q.contains("break") {
            return relationship(q)
        }
        if q.contains("move") || q.contains("relocat") || q.contains("city") || q.contains("country") {
            return relocate(q)
        }
        if q.contains("start") || q.contains("business") || q.contains("company") || q.contains("idea") {
            return startup(q)
        }
        let pool: [(String) -> DecisionResult] = [career, relationship, relocate, startup]
        return pool[abs(question.hashValue) % pool.count](q)
    }

    // MARK: – Templates

    private static func career(_ q: String) -> DecisionResult {
        let c = 72 + abs(q.hashValue % 20)
        let rem = 100 - c
        return DecisionResult(
            verdict: "Take the leap",
            confidence: c,
            isPositive: true,
            why: [
                "Growth trajectory beats current comfort",
                "Your skills match the challenge",
                "This window won't stay open"
            ],
            tradeoffs: [
                "Comfort zone disrupted",
                "New unknowns to navigate"
            ],
            report: DecisionReport(
                reasoning: [
                    "Your current role has stopped teaching you anything new.",
                    "The discomfort you feel about this offer is mostly fear of change, not a real signal.",
                    "Staying where you are isn't neutral — it costs you compound growth every month.",
                    "The skills gap you're worried about closes within 90 days of being in the role.",
                    "This kind of window doesn't reopen on your timeline."
                ],
                majorityLabel: "took it",
                majorityOutcomes: [
                    OutcomeRow(title: "Career acceleration",
                               explanation: "Fast-tracked within 12 months due to new visibility",
                               percentage: Int(Double(c) * 0.52)),
                    OutcomeRow(title: "Skill stack expanded",
                               explanation: "Gained capabilities unavailable in the previous role",
                               percentage: Int(Double(c) * 0.30)),
                    OutcomeRow(title: "Network effect",
                               explanation: "New connections changed downstream opportunities",
                               percentage: c - Int(Double(c) * 0.52) - Int(Double(c) * 0.30))
                ],
                minorityOutcomes: [
                    OutcomeRow(title: "Role misaligned",
                               explanation: "Culture or scope didn't match what was pitched",
                               percentage: Int(Double(rem) * 0.50)),
                    OutcomeRow(title: "Timing off",
                               explanation: "Personal circumstances shifted the equation",
                               percentage: Int(Double(rem) * 0.30)),
                    OutcomeRow(title: "Overfit expectations",
                               explanation: "The role evolved differently than expected",
                               percentage: rem - Int(Double(rem) * 0.50) - Int(Double(rem) * 0.30))
                ],
                topic: "career moves like this"
            )
        )
    }

    private static func relationship(_ q: String) -> DecisionResult {
        return DecisionResult(
            verdict: "Have the talk",
            confidence: 79,
            isPositive: true,
            why: [
                "Clarity now prevents bigger pain later",
                "Unspoken tension always costs energy",
                "You already know what you want"
            ],
            tradeoffs: [
                "Conversation will feel uncomfortable",
                "Outcome remains uncertain"
            ],
            report: DecisionReport(
                reasoning: [
                    "The tension between you two is burning low-grade energy every single day.",
                    "You've been rehearsing this conversation in your head — that's not anxiety, that's readiness.",
                    "Avoiding clarity now doesn't protect anyone. It just delays the same moment.",
                    "The version of you that doesn't have the talk always regrets it."
                ],
                majorityLabel: "had the talk",
                majorityOutcomes: [
                    OutcomeRow(title: "Relationship clarified",
                               explanation: "Both people understood where they actually stood",
                               percentage: 38),
                    OutcomeRow(title: "Tension released",
                               explanation: "The conversation created space that wasn't there before",
                               percentage: 26),
                    OutcomeRow(title: "New agreement reached",
                               explanation: "Something changed that made things work better",
                               percentage: 15)
                ],
                minorityOutcomes: [
                    OutcomeRow(title: "Timing wrong",
                               explanation: "The other person wasn't ready to receive it",
                               percentage: 11),
                    OutcomeRow(title: "Signals misread",
                               explanation: "The situation was different than assumed",
                               percentage: 7),
                    OutcomeRow(title: "Short-term rupture",
                               explanation: "Honest clarity created temporary pain before clarity",
                               percentage: 3)
                ],
                topic: "relationship decisions like this"
            )
        )
    }

    private static func relocate(_ q: String) -> DecisionResult {
        return DecisionResult(
            verdict: "Make the move",
            confidence: 68,
            isPositive: true,
            why: [
                "Environment shapes who you become",
                "Inertia isn't the same as belonging",
                "Your reasons to stay are mostly fear"
            ],
            tradeoffs: [
                "Built connections reset to zero",
                "Adjustment period is real"
            ],
            report: DecisionReport(
                reasoning: [
                    "The city you're in isn't the city you need anymore.",
                    "Most of your reasons to stay are about comfort, not alignment.",
                    "The people worth keeping will still be there — distance doesn't end real relationships.",
                    "Your nervous system knows the difference between home and habit."
                ],
                majorityLabel: "made the move",
                majorityOutcomes: [
                    OutcomeRow(title: "Environment unlocked growth",
                               explanation: "New context created opportunities the old one couldn't",
                               percentage: 34),
                    OutcomeRow(title: "Identity reset",
                               explanation: "Distance from the familiar clarified who they actually were",
                               percentage: 22),
                    OutcomeRow(title: "Network rebuilt stronger",
                               explanation: "New connections were more intentional and aligned",
                               percentage: 12)
                ],
                minorityOutcomes: [
                    OutcomeRow(title: "Loneliness underestimated",
                               explanation: "The first six months were harder than expected",
                               percentage: 17),
                    OutcomeRow(title: "Wrong destination",
                               explanation: "The choice of city didn't match the actual need",
                               percentage: 9),
                    OutcomeRow(title: "Timing off",
                               explanation: "Other life variables made the transition harder",
                               percentage: 6)
                ],
                topic: "relocation decisions"
            )
        )
    }

    private static func startup(_ q: String) -> DecisionResult {
        return DecisionResult(
            verdict: "Build it small first",
            confidence: 74,
            isPositive: true,
            why: [
                "Validation beats planning every time",
                "The cost of a small test is low",
                "Momentum creates its own clarity"
            ],
            tradeoffs: [
                "Time investment before any return",
                "You'll need to say no to other things"
            ],
            report: DecisionReport(
                reasoning: [
                    "The idea is real enough to start — it doesn't need to be perfect first.",
                    "Your biggest enemy right now is planning instead of shipping.",
                    "One real customer telling you it works is worth more than a year of preparation.",
                    "The version you build first won't be the version that works. That's normal.",
                    "Small and real beats large and theoretical every time."
                ],
                majorityLabel: "started small",
                majorityOutcomes: [
                    OutcomeRow(title: "Validated quickly",
                               explanation: "Real signal emerged within the first 60 days of testing",
                               percentage: 38),
                    OutcomeRow(title: "Pivoted early",
                               explanation: "First test showed what to change before it cost much",
                               percentage: 22),
                    OutcomeRow(title: "Momentum built",
                               explanation: "Starting created clarity that planning couldn't",
                               percentage: 14)
                ],
                minorityOutcomes: [
                    OutcomeRow(title: "Demand wasn't there",
                               explanation: "The problem existed but not enough people wanted a solution",
                               percentage: 14),
                    OutcomeRow(title: "Time underestimated",
                               explanation: "The real cost of testing was higher than it looked",
                               percentage: 8),
                    OutcomeRow(title: "Wrong starting point",
                               explanation: "Initial version targeted the wrong user entirely",
                               percentage: 4)
                ],
                topic: "ideas like this"
            )
        )
    }
}
