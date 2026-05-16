import SwiftUI

struct PaywallView: View {
    var onDismiss: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: Int = 1

    private var paywallVideoURL: URL? {
        Bundle.main.url(forResource: "paywall_bg", withExtension: "mov")
    }

    var body: some View {
        ZStack {
            if let url = paywallVideoURL {
                LoopingVideoView(url: url)
                    .ignoresSafeArea()
                    .scaleEffect(1.05)
                Color.black.opacity(0.72).ignoresSafeArea()
            } else {
                Color(hex: "#0A0A0A").ignoresSafeArea()
            }

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { onDismiss?(); dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(white: 0.4))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    Text("your brain.")
                        .font(.custom("HelveticaNeue", size: 42))
                        .foregroundColor(.white)
                    Text("fully awake.")
                        .font(.custom("HelveticaNeue", size: 42))
                        .foregroundColor(Color(white: 0.25))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 20)
                .padding(.trailing, 28)
                .padding(.bottom, 40)

                VStack(spacing: 0) {
                    paywallRow(icon: "infinity",
                               title: "think without limits.",
                               description: "no cap. no cooldown. whenever you need it.")
                    paywallDivider
                    paywallRow(icon: "person.fill",
                               title: "pattern identity.",
                               description: "think enough and your brain starts to reveal itself.")
                    paywallDivider
                    paywallRow(icon: "sparkles",
                               title: "full archetype.",
                               description: "every decision leaves a mark. see exactly what yours says.")
                    paywallDivider
                    paywallRow(icon: "bubble.left.fill",
                               title: "chat about any think.",
                               description: "the card was just the start. ask it everything.")
                    paywallDivider
                    paywallRow(icon: "clock.fill",
                               title: "full think history.",
                               description: "every think saved. watch how you're wired.")
                }
                .padding(.horizontal, 28)

                Spacer()

                VStack(spacing: 10) {
                    paywallPlanCard(index: 0, title: "CORE", price: "$39.99", subtitle: "500 thinks · 6 months", detail: "everything unlocked", isProBadge: false)
                    paywallPlanCard(index: 1, title: "PRO", price: "$99.99/year", subtitle: "unlimited thinks", detail: "chat + full memory", isProBadge: true)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                Button {
                    // TODO: RevenueCat purchase call
                } label: {
                    Text(selectedPlan == 0 ? "get Core — $39.99" : "start my 3-day free trial")
                        .font(.custom("HelveticaNeue", size: 17))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

                HStack(spacing: 16) {
                    Button {
                        // TODO: RevenueCat restore
                    } label: {
                        Text("restore purchase")
                            .font(.custom("HelveticaNeue", size: 12))
                            .foregroundColor(Color(white: 0.3))
                    }
                    Text("·").foregroundColor(Color(white: 0.15))
                    Button {
                        if let url = URL(string: "https://brainlabomb.com/privacy") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("privacy")
                            .font(.custom("HelveticaNeue", size: 12))
                            .foregroundColor(Color(white: 0.3))
                    }
                    Text("·").foregroundColor(Color(white: 0.15))
                    Button {
                        if let url = URL(string: "https://brainlabomb.com/terms") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("terms")
                            .font(.custom("HelveticaNeue", size: 12))
                            .foregroundColor(Color(white: 0.3))
                    }
                }
                .padding(.bottom, 8)

                if selectedPlan == 1 {
                    Text("3 days free, then $99.99/year. Cancel anytime.")
                        .font(.custom("HelveticaNeue", size: 11))
                        .foregroundColor(Color(white: 0.18))
                        .padding(.bottom, 32)
                } else {
                    Text("$39.99 one-time purchase. No subscription.")
                        .font(.custom("HelveticaNeue", size: 11))
                        .foregroundColor(Color(white: 0.18))
                        .padding(.bottom, 32)
                }
            }
        }
    }

    private func paywallPlanCard(index: Int, title: String, price: String, subtitle: String, detail: String, isProBadge: Bool) -> some View {
        let isSelected = selectedPlan == index
        return Button {
            selectedPlan = index
        } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.custom("HelveticaNeue", size: 15))
                            .foregroundColor(.white)
                        if isProBadge {
                            Text("3 DAYS FREE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    Text(subtitle)
                        .font(.custom("HelveticaNeue", size: 13))
                        .foregroundColor(Color(white: 0.4))
                    Text(detail)
                        .font(.custom("HelveticaNeue", size: 13))
                        .foregroundColor(Color(white: 0.4))
                }
                Spacer()
                Text(price)
                    .font(.custom("HelveticaNeue", size: 14))
                    .foregroundColor(.white)
            }
            .padding(16)
            .background(isSelected ? Color(white: 0.08) : Color(white: 0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color(white: 0.12), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func paywallRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(Color(white: 0.4))
                .frame(width: 22)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.custom("HelveticaNeue", size: 15))
                    .foregroundColor(.white)
                Text(description)
                    .font(.custom("HelveticaNeue", size: 13))
                    .foregroundColor(Color(white: 0.38))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.vertical, 16)
    }

    private var paywallDivider: some View {
        Rectangle()
            .fill(Color(white: 0.07))
            .frame(height: 1)
    }
}
