import SwiftUI
import PostHog

struct PaywallView: View {
    @ObservedObject var viewModel: AppViewModel
    var onDismiss: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: Int = 1
    @State private var dragOffset: CGFloat = 0
    @State private var showPurchaseError = false
    @State private var purchaseErrorMessage = ""
    @State private var showDocs = false
    @State private var docsTab = 0
    @State private var showConfirmation = false
    @State private var confirmationTier: AppTier = .core
    @State private var proPrice: String = "$99.99"
    @State private var corePrice: String = "$59.99"

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
                .padding(.top, 96)

                VStack(alignment: .leading, spacing: 6) {
                    Text("your brain.")
                        .font(.custom("HelveticaNeue", size: 42))
                        .foregroundColor(.white)
                    Text("fully awake.")
                        .font(.custom("HelveticaNeue", size: 42))
                        .foregroundColor(Color(white: 0.25))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, -40)
                .padding(.bottom, 20)

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
                    paywallPlanCard(index: 0, title: "CORE", price: corePrice, subtitle: "300 thinks · 6 months", detail: "everything unlocked", isProBadge: false)
                    paywallPlanCard(index: 1, title: "PRO", price: proPrice, subtitle: "unlimited thinks", detail: "chat + full memory", isProBadge: true)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                Button(action: {
                    Task {
                        if selectedPlan == 1 {
                            if let package = viewModel.currentOffering?.availablePackages.first(where: {
                                $0.storeProduct.productIdentifier == "com.brainla.bomb.pro.annual"
                            }) {
                                await viewModel.purchase(package: package)
                            } else {
                                purchaseErrorMessage = "Unable to load subscription. Please try again."
                                showPurchaseError = true
                            }
                        } else {
                            if let package = viewModel.currentOffering?.availablePackages.first(where: {
                                $0.storeProduct.productIdentifier == "com.brainla.bomb.core.sixmonths"
                            }) {
                                await viewModel.purchase(package: package)
                            } else {
                                purchaseErrorMessage = "Unable to load subscription. Please try again."
                                showPurchaseError = true
                            }
                        }
                    }
                }) {
                    Text(selectedPlan == 0 ? "get Core" : "start my 7-day free trial")
                        .font(.custom("HelveticaNeue", size: 17))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(viewModel.isLoadingPurchase)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

                HStack(spacing: 16) {
                    Button(action: {
                        Task {
                            let restored = await viewModel.restorePurchases()
                            if !restored {
                                await MainActor.run {
                                    purchaseErrorMessage = "No active subscription found for this Apple ID."
                                    showPurchaseError = true
                                }
                            }
                        }
                    }) {
                        Text("restore purchase")
                            .font(.custom("HelveticaNeue", size: 12))
                            .foregroundColor(Color(white: 0.3))
                    }
                    Text("·").foregroundColor(Color(white: 0.15))
                    Button {
                        docsTab = 1
                        showDocs = true
                    } label: {
                        Text("privacy")
                            .font(.custom("HelveticaNeue", size: 12))
                            .foregroundColor(Color(white: 0.3))
                    }
                    Text("·").foregroundColor(Color(white: 0.15))
                    Button {
                        docsTab = 0
                        showDocs = true
                    } label: {
                        Text("terms")
                            .font(.custom("HelveticaNeue", size: 12))
                            .foregroundColor(Color(white: 0.3))
                    }
                }
                .padding(.bottom, 8)

                if selectedPlan == 1 {
                    Text("7 days free, then \(proPrice)/year. Cancel anytime.")
                        .font(.custom("HelveticaNeue", size: 11))
                        .foregroundColor(Color(white: 0.3))
                        .padding(.bottom, 32)
                } else {
                    Text("300 thinks. \(corePrice) for 6 months. Cancel anytime.")
                        .font(.custom("HelveticaNeue", size: 11))
                        .foregroundColor(Color(white: 0.3))
                        .padding(.bottom, 32)
                }
            }
        }
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { v in
                    if v.translation.height > 0 {
                        dragOffset = v.translation.height
                    }
                }
                .onEnded { v in
                    let shouldDismiss = v.translation.height > 120
                        || v.predictedEndTranslation.height > 200
                    if shouldDismiss {
                        withAnimation(.easeOut(duration: 0.2)) { dragOffset = UIScreen.main.bounds.height }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            onDismiss?()
                            dismiss()
                        }
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .overlay {
            if viewModel.isLoadingPurchase {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                }
            }
        }
        .onAppear {
            PostHogSDK.shared.capture("paywall_viewed")
            Task {
                await viewModel.fetchOfferings()
                if let pro = viewModel.currentOffering?.availablePackages.first(where: { $0.storeProduct.productIdentifier == "com.brainla.bomb.pro.annual" }) {
                    proPrice = pro.storeProduct.localizedPriceString
                }
                if let core = viewModel.currentOffering?.availablePackages.first(where: { $0.storeProduct.productIdentifier == "com.brainla.bomb.core.sixmonths" }) {
                    corePrice = core.storeProduct.localizedPriceString
                }
                #if DEBUG
                switch UserDefaults.standard.string(forKey: "debug_currencyPreview") ?? "off" {
                case "USD": proPrice = "$99.99";      corePrice = "$59.99"
                case "GBP": proPrice = "£79.99";      corePrice = "£49.99"
                case "SGD": proPrice = "S$129.99";    corePrice = "S$79.99"
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
        .sheet(isPresented: $showDocs) { DocsView(initialTab: docsTab) }
        .fullScreenCover(isPresented: $showConfirmation) {
            PaymentConfirmationView(tier: confirmationTier) {
                showConfirmation = false
                onDismiss?()
                dismiss()
            }
        }
        .onChange(of: viewModel.hasActiveEntitlement) { hasIt in
            guard hasIt, !showConfirmation else { return }
            let tier = viewModel.purchasedTier
            PostHogSDK.shared.capture("purchase_completed", properties: ["tier": tier == .pro ? "pro" : "core"])
            confirmationTier = tier
            showConfirmation = true
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
                            Text("7 DAYS FREE")
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

