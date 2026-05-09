import SwiftUI

struct InputPageView: View {
    let onSubmit: (String) -> Void
    let onDismiss: () -> Void

    @State private var text = ""
    @FocusState private var focused: Bool

    private var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // ── Header ───────────────────────────────────────────────────
                HStack(alignment: .center) {
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Color(white: 0.45))
                            .frame(width: 40, height: 40)
                    }

                    Spacer()

                    if canSubmit {
                        Button {
                            let q = text.trimmingCharacters(in: .whitespacesAndNewlines)
                            onSubmit(q)
                        } label: {
                            HStack(spacing: 6) {
                                Text("Decide")
                                    .font(.system(size: 15, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .clipShape(Capsule())
                        }
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .animation(.spring(response: 0.35), value: canSubmit)

                // ── Heading ──────────────────────────────────────────────────
                Text("What's on\nyour mind?")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .lineSpacing(2)
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 20)

                // ── Text editor ──────────────────────────────────────────────
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.white)
                        .tint(.white)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .focused($focused)
                        .padding(.horizontal, 20)

                    if text.isEmpty {
                        Text("Describe what you're deciding.\nBe as vague or specific as you want.")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(Color(white: 0.22))
                            .lineSpacing(4)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                }

                Spacer()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { focused = true }
        }
    }
}
