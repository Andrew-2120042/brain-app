import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.appState {
            case .result(let r):
                DecisionCardView(
                    result: r,
                    originalQuestion: viewModel.originalQuestion,
                    onReset: { withAnimation(.easeInOut(duration: 0.35)) { viewModel.reset() } },
                    allowSwipeDismiss: false
                )
                .transition(.opacity)

            case .question(let q):
                QuestionCardView(
                    question: q,
                    onSubmit: { answer in viewModel.submitFollowUp(answer: answer) },
                    onSkip:   { viewModel.skipFollowUp() }
                )
                .transition(.opacity)

            case .processingFirst, .processingSecond:
                SimulatingView()
                    .transition(.opacity)

            case .input:
                InputPageView(
                    onSubmit: { question in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.submitQuestion(question)
                        }
                    },
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.reset()
                        }
                    }
                )
                .transition(.opacity)

            case .error(let msg):
                ErrorView(message: msg) {
                    viewModel.retry()
                } onDismiss: {
                    viewModel.reset()
                }
                .transition(.opacity)

            case .home:
                HomeView(isProcessing: false) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.appState = .input
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: screenKey)
    }

    private var screenKey: Int {
        switch viewModel.appState {
        case .result:           return 5
        case .question:         return 4
        case .processingSecond: return 3
        case .processingFirst:  return 2
        case .input:            return 1
        case .error:            return 6
        case .home:             return 0
        }
    }
}

// MARK: - Error View
private struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.039, green: 0.039, blue: 0.039).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("SOMETHING WENT WRONG")
                    .font(.custom("HelveticaNeue", size: 12))
                    .foregroundColor(Color(white: 0.4))
                    .tracking(1.5)
                    .padding(.top, 64)
                    .padding(.horizontal, 28)

                Text(message)
                    .font(.custom("HelveticaNeue", size: 18))
                    .foregroundColor(Color(white: 0.7))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 24)
                    .padding(.horizontal, 28)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: onRetry) {
                        Text("Try again")
                            .font(.custom("HelveticaNeue", size: 16))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: onDismiss) {
                        Text("Back to home")
                            .font(.custom("HelveticaNeue", size: 14))
                            .foregroundColor(Color(white: 0.4))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 52)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
