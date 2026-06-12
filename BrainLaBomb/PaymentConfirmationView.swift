import SwiftUI

struct PaymentConfirmationView: View {
    let tier: AppTier
    var onDismiss: () -> Void

    @State private var phase: Int = 0

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Image(systemName: "crown.fill")
                    .font(.system(size: 56, weight: .regular))
                    .foregroundColor(.white)
                    .scaleEffect(phase >= 1 ? 1.0 : 0.6)
                    .opacity(phase >= 1 ? 1 : 0)
                    .padding(.bottom, 36)

                Text(tier == .pro ? "you're in." : "you're in.")
                    .font(.custom("HelveticaNeue", size: 30))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(phase >= 2 ? 1 : 0)
                    .padding(.bottom, 14)

                Text(tier == .pro
                     ? "unlimited thinks unlocked.\nthe brain is yours now."
                     : "300 thinks unlocked.\nstart bringing it something real.")
                    .font(.custom("Poppins-Regular", size: 15))
                    .foregroundColor(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .opacity(phase >= 3 ? 1 : 0)
                    .padding(.horizontal, 36)

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Text("got it")
                        .font(.custom("HelveticaNeue", size: 17))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
                .opacity(phase >= 4 ? 1 : 0)
            }
        }
        .onAppear {
            phase = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) { phase = 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.easeIn(duration: 0.4)) { phase = 2 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
                withAnimation(.easeIn(duration: 0.4)) { phase = 3 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
                withAnimation(.easeIn(duration: 0.4)) { phase = 4 }
            }
        }
    }
}
