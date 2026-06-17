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
    @State private var weeklyPrice: String = "$5.99"
    @State private var proMonthly: String = "$8.33"
    @State private var coreMonthly: String = "$10.00"
    @State private var weeklyDaily: String = "$0.85"

    private var paywallVideoURL: URL? {
        Bundle.main.url(forResource: "paywall_bg", withExtension: "mov")
    }

    var body: some View {
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
                .padding(.top, 14)
                .offset(y: 26)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Brain.")
                        .font(.custom("HelveticaNeue", size: 42))
                        .foregroundColor(.white)
                    Text("Fully Awake.")
                        .font(.custom("HelveticaNeue", size: 42))
                        .foregroundColor(Color(white: 0.25))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .padding(.bottom, 16)

                VStack(spacing: 0) {
                    paywallRow(icon: "infinity",
                               title: "Think Without Limits.",
                               description: "Whenever you need it. However often you need it.")
                    paywallDivider
                    paywallRow(icon: "sparkles",
                               title: "Pattern + Archetype.",
                               description: "See exactly how you think and decide.")
                    paywallDivider
                    paywallRow(icon: "bubble.left.fill",
                               title: "Chat About Any Think.",
                               description: "The card was just the start. Ask it everything.")
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 16)

                Spacer(minLength: 16)

                VStack(spacing: 14) {
                    paywallPlanCard(index: 2, productId: "com.brainla.bomb.pro.weekly", title: "WEEKLY", price: "\(weeklyDaily)/day", subtitle: "7 Days Free Trial", detail: "Cancel Anytime", isProBadge: false, priceCaption: "Billed weekly at \(weeklyPrice)")
                    paywallPlanCard(index: 0, productId: "com.brainla.bomb.core.sixmonths.v2", title: "CORE", price: "\(coreMonthly)/mo", subtitle: "300 Thinks", detail: "Everything Unlocked", isProBadge: false, priceCaption: "Billed every 6 months at \(corePrice)")
                    paywallPlanCard(index: 1, productId: "com.brainla.bomb.pro.annual.v2", title: "PRO", price: "\(proMonthly)/mo", subtitle: "Unlimited Thinks", detail: "Chat + Full Memory", isProBadge: true, priceCaption: "Billed annually at \(proPrice)")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                Button(action: {
                    Task {
                        let productId: String
                        let selectedTier: AppTier
                        switch selectedPlan {
                        case 1:  productId = "com.brainla.bomb.pro.annual.v2";   selectedTier = .pro
                        case 2:  productId = "com.brainla.bomb.pro.weekly";      selectedTier = .pro
                        default: productId = "com.brainla.bomb.core.sixmonths.v2"; selectedTier = .core
                        }
                        print("DEBUG in-app paywall buy: selectedPlan=\(selectedPlan), selectedTier=\(selectedTier)")
                        guard let package = viewModel.currentOffering?.availablePackages.first(where: {
                            $0.storeProduct.productIdentifier == productId
                        }) else {
                            await MainActor.run {
                                purchaseErrorMessage = "Unable to load subscription. Please try again."
                                showPurchaseError = true
                            }
                            return
                        }
                        let success = await viewModel.purchase(package: package)
                        if success {
                            await MainActor.run {
                                print("DEBUG in-app confirmation tier = \(selectedTier)")
                                confirmationTier = selectedTier
                                showConfirmation = true
                            }
                        }
                    }
                }) {
                    Text({
                        switch selectedPlan {
                        case 1: return "Start My 7-Day Free Trial"
                        case 2: return "Try Weekly · 7 Days Free"
                        default: return "Get Core"
                        }
                    }())
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

                if selectedPlan == 1 {
                    Text("7 Days Free, Then \(proPrice)/Year. Cancel Anytime.")
                        .font(.custom("HelveticaNeue", size: 13))
                        .foregroundColor(Color(white: 0.4))
                        .padding(.bottom, 8)
                } else if selectedPlan == 2 {
                    Text("7 Days Free, Then \(weeklyPrice)/Week. Cancel Anytime.")
                        .font(.custom("HelveticaNeue", size: 13))
                        .foregroundColor(Color(white: 0.4))
                        .padding(.bottom, 8)
                } else {
                    Text("300 Thinks. \(corePrice) For 6 Months. Cancel Anytime.")
                        .font(.custom("HelveticaNeue", size: 13))
                        .foregroundColor(Color(white: 0.4))
                        .padding(.bottom, 8)
                }

                HStack(spacing: 16) {
                    Button(action: {
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
                    }) {
                        Text("Restore Purchase")
                            .font(.custom("HelveticaNeue", size: 12))
                            .foregroundColor(Color(white: 0.3))
                    }
                    Text("·").foregroundColor(Color(white: 0.15))
                    Button {
                        if let url = URL(string: "https://creative-sailfish-dc6.notion.site/privacy-policy-3647cd351f5b807b9021d48d42a71a0b?source=copy_link") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Privacy")
                            .font(.custom("HelveticaNeue", size: 12))
                            .foregroundColor(Color(white: 0.3))
                    }
                    Text("·").foregroundColor(Color(white: 0.15))
                    Button {
                        if let url = URL(string: "https://creative-sailfish-dc6.notion.site/Terms-and-conditions-3647cd351f5b8000b482d1062d00f0ad?source=copy_link") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Terms")
                            .font(.custom("HelveticaNeue", size: 12))
                            .foregroundColor(Color(white: 0.3))
                    }
                }
                .padding(.bottom, 8)
            }
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if let url = paywallVideoURL {
                    ZStack {
                        LoopingVideoView(url: url)
                            .scaleEffect(1.05)
                        Color.black.opacity(0.72)
                    }
                    .ignoresSafeArea()
                } else {
                    Color(hex: "#0A0A0A").ignoresSafeArea()
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
                if let pro = viewModel.currentOffering?.availablePackages.first(where: { $0.storeProduct.productIdentifier == "com.brainla.bomb.pro.annual.v2" }) {
                    proPrice = pro.storeProduct.localizedPriceString
                    proMonthly = pro.storeProduct.localizedPricePerMonth ?? proMonthly
                }
                if let core = viewModel.currentOffering?.availablePackages.first(where: { $0.storeProduct.productIdentifier == "com.brainla.bomb.core.sixmonths.v2" }) {
                    corePrice = core.storeProduct.localizedPriceString
                    coreMonthly = core.storeProduct.localizedPricePerMonth ?? coreMonthly
                }
                if let weekly = viewModel.currentOffering?.availablePackages.first(where: { $0.storeProduct.productIdentifier == "com.brainla.bomb.pro.weekly" }) {
                    weeklyPrice = weekly.storeProduct.localizedPriceString
                    weeklyDaily = weekly.storeProduct.localizedPricePerDay ?? weeklyDaily
                }
                #if DEBUG
                switch UserDefaults.standard.string(forKey: "debug_currencyPreview") ?? "off" {
                case "USD": proPrice = "$99.99";      corePrice = "$59.99";    weeklyPrice = "$5.99";   proMonthly = "$8.33";    coreMonthly = "$10.00";   weeklyDaily = "$0.85"
                case "GBP": proPrice = "£79.99";      corePrice = "£49.99";    weeklyPrice = "£4.99";   proMonthly = "£6.67";    coreMonthly = "£8.33";    weeklyDaily = "£0.71"
                case "SGD": proPrice = "S$129.99";    corePrice = "S$79.99";   weeklyPrice = "S$7.99";  proMonthly = "S$10.83";  coreMonthly = "S$13.33";  weeklyDaily = "S$1.14"
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
    }

    private func paywallPlanCard(index: Int, productId: String, title: String, price: String, subtitle: String, detail: String, isProBadge: Bool, priceCaption: String? = nil) -> some View {
        let isSelected = selectedPlan == index
        let isCurrent = viewModel.hasActiveEntitlement && viewModel.activeProductIdentifier == productId
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
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.white, lineWidth: 1)
                                )
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
                VStack(alignment: .trailing, spacing: 3) {
                    Text(price)
                        .font(.custom("HelveticaNeue", size: 14))
                        .foregroundColor(.white)
                    if let priceCaption {
                        Text(priceCaption)
                            .font(.custom("HelveticaNeue", size: 12))
                            .foregroundColor(Color(white: 0.4))
                    }
                }
            }
            .padding(16)
            .background(isSelected ? Color(white: 0.08) : Color(white: 0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color(white: 0.12), lineWidth: 1)
            )
            .overlay(alignment: .bottomTrailing) {
                if isCurrent {
                    Text("CURRENT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.black)
                        .tracking(0.5)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .padding(.trailing, 12)
                        .padding(.bottom, 10)
                } else if isProBadge {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8, weight: .bold))
                        Text("MOST POPULAR")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.5)
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .padding(.trailing, 12)
                    .padding(.bottom, 10)
                }
            }
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
        .padding(.vertical, 12)
    }

    private var paywallDivider: some View {
        Rectangle()
            .fill(Color(white: 0.07))
            .frame(height: 1)
    }
}

