import SwiftUI

struct QuestionCardView: View {
    let question: String
    let onSubmit: (String) -> Void
    let onSkip:   () -> Void

    @State private var answer = ""
    @FocusState private var focused: Bool

    private var canSend: Bool {
        !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func dismissAndAct(_ action: @escaping () -> Void) {
        focused = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) { action() }
    }

    var body: some View {
        ZStack {
            Color(red: 0.039, green: 0.039, blue: 0.039).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // ── Top label ─────────────────────────────────────────────────
                Text("ONE THING FIRST")
                    .font(.custom("HelveticaNeue", size: 12))
                    .foregroundColor(Color(white: 0.4))
                    .tracking(1.5)
                    .padding(.top, 64)
                    .padding(.horizontal, 28)

                // ── Question ──────────────────────────────────────────────────
                Text(question)
                    .font(.custom("HelveticaNeue", size: 26))
                    .foregroundColor(Color(white: 0.96))
                    .lineSpacing(8)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 28)
                    .padding(.horizontal, 28)

                // ── Hint ──────────────────────────────────────────────────────
                Text("your answer helps me think more clearly")
                    .font(.custom("HelveticaNeue", size: 13))
                    .foregroundColor(Color(white: 0.4))
                    .padding(.top, 12)
                    .padding(.horizontal, 28)

                Spacer()

                // ── Input + actions ───────────────────────────────────────────
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("your answer...", text: $answer, axis: .vertical)
                            .font(.custom("HelveticaNeue", size: 16))
                            .foregroundColor(.white)
                            .tint(.white)
                            .lineLimit(1...4)
                            .focused($focused)

                        Rectangle()
                            .fill(Color(white: 0.2))
                            .frame(height: 0.5)
                    }
                    .padding(.horizontal, 28)

                    HStack {
                        Button { dismissAndAct { onSkip() } } label: {
                            Text("skip →")
                                .font(.custom("HelveticaNeue", size: 13))
                                .foregroundColor(Color(white: 0.33))
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer()

                        Button { dismissAndAct { onSubmit(answer) } } label: {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(width: 40, height: 40)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(!canSend)
                        .opacity(canSend ? 1 : 0.25)
                    }
                    .padding(.horizontal, 28)
                }
                .padding(.bottom, 36)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear { focused = true }
    }
}
