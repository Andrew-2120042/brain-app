import SwiftUI

struct ContentView: View {
    @State private var showInput   = false
    @State private var processing  = false
    @State private var followUpQ:  String? = nil
    @State private var pendingQ:   String  = ""
    @State private var result:     DecisionResult? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let r = result {
                DecisionCardView(result: r) {
                    withAnimation(.easeInOut(duration: 0.35)) { result = nil }
                }
                .transition(.opacity)

            } else if let q = followUpQ {
                QuestionCardView(
                    question: q,
                    onSubmit: { answer in runSecondPass(answer: answer) },
                    onSkip:   { runSecondPass(answer: "") }
                )
                .transition(.opacity)

            } else if processing {
                SimulatingView()
                    .transition(.opacity)

            } else if showInput {
                InputPageView { question in
                    pendingQ = question
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showInput  = false
                        processing = true
                    }
                    runFirstPass(question: question)
                }
                .transition(.opacity)

            } else {
                HomeView(isProcessing: false) {
                    withAnimation(.easeInOut(duration: 0.3)) { showInput = true }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: screenKey)
    }

    // composite key so a single animation modifier drives all transitions
    private var screenKey: Int {
        if result    != nil  { return 4 }
        if followUpQ != nil  { return 3 }
        if processing        { return 2 }
        if showInput         { return 1 }
        return 0
    }

    // ── Pass 1 ────────────────────────────────────────────────────────────────
    private func runFirstPass(question: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            let pass = DecisionEngine.firstPass(question: question)
            if pass.needsQuestion, let fq = pass.followUpQuestion {
                withAnimation(.easeInOut(duration: 0.35)) {
                    processing = false
                    followUpQ  = fq
                }
            } else {
                let r = DecisionEngine.decide(question: question)
                withAnimation(.easeInOut(duration: 0.35)) {
                    processing = false
                    result     = r
                }
            }
        }
    }

    // ── Pass 2 ────────────────────────────────────────────────────────────────
    private func runSecondPass(answer: String) {
        // keyboard is already dismissed by dismissAndAct — transition both states together
        withAnimation(.easeInOut(duration: 0.3)) {
            followUpQ  = nil
            processing = true
        }
        let combined = answer.isEmpty ? pendingQ : "\(pendingQ). \(answer)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            let r = DecisionEngine.decide(question: combined)
            withAnimation(.easeInOut(duration: 0.35)) {
                processing = false
                result     = r
            }
        }
    }
}
