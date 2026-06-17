import SwiftUI
import PostHog
import RevenueCat

struct DownsellWeeklyView: View {
    @ObservedObject var viewModel: AppViewModel
    var onDismiss: () -> Void

    @State private var weeklyPrice: String = "$5.99"
    @State private var weeklyDaily: String = "$0.85"
    @State private var isPurchasing = false
    @State private var showPurchaseError = false
    @State private var purchaseErrorMessage = ""
    @State private var showConfirmation = false
    @State private var confirmationTier: AppTier = .pro

    private static let weeklyProductId = "com.brainla.bomb.pro.weekly"

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
                VStack(alignment: .leading, spacing: 6) {
                    Text("Not Ready to Commit Yet?")
                        .font(.custom("HelveticaNeue", size: 42))
                        .foregroundColor(.white)
                    Text("Try Bracket for a Week.")
                        .font(.custom("HelveticaNeue", size: 42))
                        .foregroundColor(Color(white: 0.55))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 44)

                Spacer()

                weeklyCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                Button(action: {
                    Task { await purchaseWeekly() }
                }) {
                    Group {
                        if isPurchasing {
                            ProgressView().tint(.black)
                        } else {
                            Text("Try free for 7 days")
                                .font(.custom("HelveticaNeue", size: 17))
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isPurchasing || viewModel.isLoadingPurchase)
                .padding(.horizontal, 24)
                .padding(.bottom, 14)

                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(white: 0.65))
                    Text("No Commitment  ·  Cancel Anytime")
                        .font(.custom("HelveticaNeue-Bold", size: 14))
                        .foregroundColor(Color(white: 0.7))
                }
                .padding(.bottom, 14)

                Text("\(weeklyPrice)/week. Billed weekly. Subscription auto-renews each week unless you cancel. Cancel anytime in the App Store.")
                    .font(.custom("HelveticaNeue", size: 12))
                    .foregroundColor(Color(white: 0.4))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 16)

                HStack(spacing: 16) {
                    Button {
                        Task {
                            let restored = await viewModel.restorePurchases()
                            if restored {
                                await MainActor.run {
                                    confirmationTier = viewModel.activeTier
                                    showConfirmation = true
                                }
                            } else {
                                await MainActor.run {
                                    purchaseErrorMessage = "No active subscription found for this Apple ID."
                                    showPurchaseError = true
                                }
                            }
                        }
                    } label: {
                        Text("Restore")
                            .font(.custom("HelveticaNeue", size: 13))
                            .foregroundColor(Color(white: 0.4))
                    }
                    Text("·").foregroundColor(Color(white: 0.18))
                    Button {
                        if let url = URL(string: "https://creative-sailfish-dc6.notion.site/privacy-policy-3647cd351f5b807b9021d48d42a71a0b?source=copy_link") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Privacy")
                            .font(.custom("HelveticaNeue", size: 13))
                            .foregroundColor(Color(white: 0.4))
                    }
                    Text("·").foregroundColor(Color(white: 0.18))
                    Button {
                        if let url = URL(string: "https://creative-sailfish-dc6.notion.site/Terms-and-conditions-3647cd351f5b8000b482d1062d00f0ad?source=copy_link") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Terms")
                            .font(.custom("HelveticaNeue", size: 13))
                            .foregroundColor(Color(white: 0.4))
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .overlay {
            if viewModel.isLoadingPurchase {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    ProgressView().tint(.white).scaleEffect(1.5)
                }
            }
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Spacer()
                Button {
                    PostHogSDK.shared.capture("downsell_dismissed")
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(white: 0.4))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 8)
        }
        .onAppear {
            PostHogSDK.shared.capture("downsell_viewed")
            if viewModel.hasActiveEntitlement {
                onDismiss()
                return
            }
            Task {
                await viewModel.fetchOfferings()
                if let weekly = viewModel.currentOffering?.availablePackages.first(where: {
                    $0.storeProduct.productIdentifier == Self.weeklyProductId
                }) {
                    weeklyPrice = weekly.storeProduct.localizedPriceString
                    weeklyDaily = weekly.storeProduct.localizedPricePerDay ?? weeklyDaily
                }
                #if DEBUG
                switch UserDefaults.standard.string(forKey: "debug_currencyPreview") ?? "off" {
                case "USD": weeklyPrice = "$5.99";   weeklyDaily = "$0.85"
                case "GBP": weeklyPrice = "£4.99";   weeklyDaily = "£0.71"
                case "SGD": weeklyPrice = "S$7.99";  weeklyDaily = "S$1.14"
                default: break
                }
                #endif
            }
        }
        .alert("Purchase Failed", isPresented: $showPurchaseError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseErrorMessage)
        }
        .fullScreenCover(isPresented: $showConfirmation) {
            PaymentConfirmationView(tier: confirmationTier) {
                showConfirmation = false
                onDismiss()
            }
        }
    }

    private var weeklyCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("7 DAYS FREE TRIAL")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .tracking(1.2)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color.white)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekly Plan")
                            .font(.custom("HelveticaNeue-Bold", size: 18))
                            .foregroundColor(.white)
                        Text("Cancel Anytime")
                            .font(.custom("HelveticaNeue", size: 13))
                            .foregroundColor(Color(white: 0.45))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("\(weeklyDaily)/day")
                            .font(.custom("HelveticaNeue-Bold", size: 18))
                            .foregroundColor(.white)
                        Text("Billed weekly at \(weeklyPrice)")
                            .font(.custom("HelveticaNeue", size: 12))
                            .foregroundColor(Color(white: 0.45))
                    }
                }

                Rectangle().fill(Color(white: 0.18)).frame(height: 1)

                Text("Unlimited Thinks  ·  Full Memory  ·  All Archetypes")
                    .font(.custom("HelveticaNeue", size: 12))
                    .foregroundColor(Color(white: 0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 16,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 16
                )
                .fill(Color(white: 0.08))
            )
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white, lineWidth: 1)
        )
    }

    private func purchaseWeekly() async {
        guard let package = viewModel.currentOffering?.availablePackages.first(where: {
            $0.storeProduct.productIdentifier == Self.weeklyProductId
        }) else {
            purchaseErrorMessage = "Unable to load subscription. Please try again."
            showPurchaseError = true
            return
        }
        isPurchasing = true
        let success = await viewModel.purchase(package: package)
        isPurchasing = false
        if success {
            confirmationTier = .pro
            showConfirmation = true
        }
    }
}
