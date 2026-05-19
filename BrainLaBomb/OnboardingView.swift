import SwiftUI
import UserNotifications

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var currentScreen = 0
    @State private var quiz1Selection: Int? = nil
    @State private var quiz2Selection: Int? = nil
    @State private var quiz3Selection: Int? = nil
    @State private var progress: CGFloat = 0
    @State private var brainReady = false
    @State private var selectedPlan: Int = 2

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A").ignoresSafeArea()

            switch currentScreen {
            case 0:  screenOne.transition(.opacity)
            case 1:  screenTwo.transition(.opacity)
            case 2:  consentScreen.transition(.opacity)
            case 3:  screenQuiz1.transition(.opacity)
            case 4:  screenQuiz2.transition(.opacity)
            case 5:  screenQuiz3.transition(.opacity)
            case 6:  screenBuildingBrain.transition(.opacity)
            case 7:  screenHowItWorks.transition(.opacity)
            case 8:  screenNotifications.transition(.opacity)
            case 9:  screenPaywall.transition(.opacity)
            case 10: screenDone.transition(.opacity)
            default: screenOne.transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: currentScreen)
    }

    // MARK: - Screen 0

    private var screenOne: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 0) {
                Text("you already know\nwhat you should do.")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(32 * 0.3)
                Spacer().frame(height: 20)
                Text("you just need something\nto think it through with you.")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(28 * 0.3)
            }
            Spacer()
            onboardingButton("I'm ready") { currentScreen = 1 }
                .padding(.bottom, 52)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Screen 1

    private var screenTwo: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 0) {
                Text("this isn't advice.")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Spacer().frame(height: 24)
                Text("it's your situation,\nrun through thousands\nof possible outcomes.\n\nthen handed back to you.")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(24 * 0.5)
            }
            Spacer()
            onboardingButton("that's different") { currentScreen = 2 } // → consent screen
                .padding(.bottom, 52)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Screen 2 — Consent

    private var consentScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text("before we begin.")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
            Text("your thinks are processed by Claude AI.\nwhat you share leaves your device\nto generate a response.")
                .font(.system(size: 22, weight: .light))
                .foregroundColor(.white.opacity(0.5))
                .lineSpacing(6)
                .padding(.horizontal, 32)
                .padding(.bottom, 12)
            Text("we don't store your thinks.\nno servers. no profiles. no ads.\neverything stays between you and the brain.")
                .font(.system(size: 22, weight: .light))
                .foregroundColor(.white.opacity(0.5))
                .lineSpacing(6)
                .padding(.horizontal, 32)
                .padding(.bottom, 12)
            Text("the brain provides perspective.\nnot instructions.\nall decisions remain entirely yours.")
                .font(.system(size: 22, weight: .light))
                .foregroundColor(.white.opacity(0.5))
                .lineSpacing(6)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
            Button(action: {
                UserDefaults.standard.set(true, forKey: "hasGivenAIConsent")
                withAnimation(.easeInOut(duration: 0.4)) { currentScreen = 3 }
            }) {
                Text("I understand and agree")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 12)
            HStack {
                Spacer()
                Button(action: {
                    if let url = URL(string: "https://creative-sailfish-dc6.notion.site/privacy-policy-3647cd351f5b807b9021d48d42a71a0b") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("read our privacy policy")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.3))
                        .underline()
                }
                .buttonStyle(PlainButtonStyle())
                Spacer()
            }
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Screen 3 — Quiz 1

    private let quiz1Options = [
        "constantly — almost every day",
        "often — a few times a week",
        "sometimes — once in a while",
        "rarely — but when I do they're heavy"
    ]

    private var screenQuiz1: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 0) {
                Text("01 of 03")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                Spacer().frame(height: 32)
                Text("how often do you face decisions\nyou can't stop thinking about?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(28 * 0.3)
                Spacer().frame(height: 32)
                VStack(spacing: 10) {
                    ForEach(0..<quiz1Options.count, id: \.self) { i in
                        quizPill(quiz1Options[i], selected: quiz1Selection == i) {
                            quiz1Selection = i
                        }
                    }
                }
            }
            Spacer()
            onboardingButton("continue") { currentScreen = 4 }
                .padding(.bottom, 52)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Screen 4 — Quiz 2

    private let quiz2Options = [
        "knowing what I actually want",
        "overthinking every angle",
        "being too emotional to think clearly",
        "caring too much what others think"
    ]

    private var screenQuiz2: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 0) {
                Text("02 of 03")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                Spacer().frame(height: 32)
                Text("what do you struggle\nwith most?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(28 * 0.3)
                Spacer().frame(height: 32)
                VStack(spacing: 10) {
                    ForEach(0..<quiz2Options.count, id: \.self) { i in
                        quizPill(quiz2Options[i], selected: quiz2Selection == i) {
                            quiz2Selection = i
                        }
                    }
                }
            }
            Spacer()
            onboardingButton("continue") { currentScreen = 5 }
                .padding(.bottom, 52)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Screen 5 — Quiz 3

    private let quiz3Options = [
        "late at night when everything gets loud",
        "during big life changes",
        "when relationships get complicated",
        "when work and life collide"
    ]

    private var screenQuiz3: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 0) {
                Text("03 of 03")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                Spacer().frame(height: 32)
                Text("when do you usually\nface these moments?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(28 * 0.3)
                Spacer().frame(height: 32)
                VStack(spacing: 10) {
                    ForEach(0..<quiz3Options.count, id: \.self) { i in
                        quizPill(quiz3Options[i], selected: quiz3Selection == i) {
                            quiz3Selection = i
                        }
                    }
                }
            }
            Spacer()
            onboardingButton("continue") { currentScreen = 6 }
                .padding(.bottom, 52)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Screen 6 — Building Brain

    private var screenBuildingBrain: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
                Text(brainReady ? "your brain is ready." : "building your brain.")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .id(brainReady)
                    .transition(.opacity)

                Rectangle()
                    .fill(Color(white: 0.12))
                    .frame(height: 2)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(height: 2)
                            .scaleEffect(x: progress, y: 1, anchor: .leading)
                    }

                if brainReady {
                    Text("trained for the way you think.")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 30)
            Spacer()
        }
        .onAppear {
            progress = 0
            brainReady = false
            withAnimation(.linear(duration: 2)) {
                progress = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    brainReady = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                currentScreen = 7
            }
        }
    }

    // MARK: - Screen 7 — How It Works

    private var screenHowItWorks: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 0) {
                Text("how it works.")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Spacer().frame(height: 40)
                VStack(spacing: 0) {
                    howItWorksBlock(number: "01", title: "bring it anything.", body: "a decision. a feeling. something\nsitting with you.")
                    Rectangle().fill(Color(white: 0.07)).frame(height: 1)
                    howItWorksBlock(number: "02", title: "the brain simulates it.", body: "thousands of outcomes.\nrun silently in seconds.")
                    Rectangle().fill(Color(white: 0.07)).frame(height: 1)
                    howItWorksBlock(number: "03", title: "you get clarity.", body: "a verdict. the reasoning.\nwhat most outcomes showed.")
                }
            }
            Spacer()
            onboardingButton("I'm ready") { currentScreen = 8 }
                .padding(.bottom, 52)
        }
        .padding(.horizontal, 24)
    }

    private func howItWorksBlock(number: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(number)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(white: 0.3))
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            Text(body)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.white.opacity(0.5))
                .lineSpacing(16 * 0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 20)
    }

    // MARK: - Screen 8 — Notifications

    private var screenNotifications: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 0) {
                Text("decisions don't only happen\nduring business hours.")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(28 * 0.3)
                Spacer().frame(height: 20)
                Text("let the brain find you\nwhen something's sitting with you.")
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(22 * 0.5)
            }
            Spacer()
            VStack(spacing: 12) {
                onboardingButton("yes, find me") {
                    requestNotificationPermission { currentScreen = 9 }
                }
                Button {
                    currentScreen = 9
                } label: {
                    Text("not yet")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 52)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Screen 9 — Onboarding Paywall

    private var screenPaywall: some View {
        GeometryReader { proxy in
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: proxy.safeAreaInsets.top + 24)

                Text("unlock your brain.")
                    .font(.custom("HelveticaNeue", size: 32))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)

                VStack(spacing: 10) {
                    onboardingPlanCard(
                        index: 0,
                        title: "FREE",
                        price: nil,
                        subtitle: "5 thinks to start",
                        detail: "try the brain",
                        rightBadge: "current",
                        isProBadge: false,
                        isFree: true
                    )
                    onboardingPlanCard(
                        index: 1,
                        title: "CORE",
                        price: "$39.99",
                        subtitle: "500 thinks · 6 months",
                        detail: "everything unlocked",
                        rightBadge: nil,
                        isProBadge: false,
                        isFree: false
                    )
                    onboardingPlanCard(
                        index: 2,
                        title: "PRO",
                        price: "$99.99/year",
                        subtitle: "unlimited thinks",
                        detail: "chat + full memory",
                        rightBadge: nil,
                        isProBadge: true,
                        isFree: false
                    )
                }
                .padding(.horizontal, 24)

                if selectedPlan == 2 {
                    VStack(spacing: 16) {
                        Text("No Payment Due Today")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(white: 0.4))
                            .frame(maxWidth: .infinity, alignment: .center)
                        VStack(spacing: 10) {
                            trialTimelineRow(day: "Today", text: "Unlock everything. No charge.")
                            trialTimelineRow(day: "Day 2", text: "Reminder before trial ends.")
                            trialTimelineRow(day: "Day 3", text: "Billing starts unless cancelled.")
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .transition(.opacity)
                }

                Spacer().frame(height: 28)

                Group {
                    if selectedPlan == 0 {
                        Button {
                            currentScreen = 10
                        } label: {
                            Text("continue for free")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white, lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        onboardingButton(selectedPlan == 1 ? "get Core — $39.99" : "start my 3-day free trial") {
                            // TODO: RevenueCat purchase call
                            currentScreen = 10
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

                HStack(spacing: 16) {
                    Button { } label: {
                        Text("restore purchase")
                            .font(.custom("HelveticaNeue", size: 12))
                            .foregroundColor(Color(white: 0.3))
                    }
                    Text("·").foregroundColor(Color(white: 0.15))
                    Button {
                        if let url = URL(string: "https://creative-sailfish-dc6.notion.site/Terms-and-conditions-3647cd351f5b8000b482d1062d00f0ad") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("terms")
                            .font(.custom("HelveticaNeue", size: 12))
                            .foregroundColor(Color(white: 0.3))
                    }
                    Text("·").foregroundColor(Color(white: 0.15))
                    Button {
                        if let url = URL(string: "https://creative-sailfish-dc6.notion.site/privacy-policy-3647cd351f5b807b9021d48d42a71a0b") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("privacy")
                            .font(.custom("HelveticaNeue", size: 12))
                            .foregroundColor(Color(white: 0.3))
                    }
                }
                .padding(.bottom, 8)

                if selectedPlan == 2 {
                    Text("3 days free, then $99.99/year. Cancel anytime.")
                        .font(.custom("HelveticaNeue", size: 11))
                        .foregroundColor(Color(white: 0.18))
                        .padding(.bottom, 32)
                } else {
                    Spacer().frame(height: 32)
                }
            }
        }
        }
    }

    private func onboardingPlanCard(
        index: Int,
        title: String,
        price: String?,
        subtitle: String,
        detail: String,
        rightBadge: String?,
        isProBadge: Bool,
        isFree: Bool
    ) -> some View {
        let isSelected = selectedPlan == index
        return Button {
            selectedPlan = index
        } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(isFree ? Color(white: 0.3) : .white)
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
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(isFree ? Color(white: 0.3) : Color(white: 0.4))
                    Text(detail)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(isFree ? Color(white: 0.3) : Color(white: 0.4))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    if let price = price {
                        Text(price)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    if let badge = rightBadge {
                        Text(badge)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(white: 0.3))
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
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func trialTimelineRow(day: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(day)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(white: 0.4))
                .frame(width: 44, alignment: .leading)
            Text(text)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(white: 0.6))
            Spacer()
        }
    }

    // MARK: - Screen 10 — Done

    private var screenDone: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 0) {
                Text("you're ready.")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Spacer().frame(height: 20)
                Text("bring it something real.")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            Spacer()
            VStack(spacing: 12) {
                onboardingButton("let's go") {
                    onComplete()
                }
                if selectedPlan == 0 {
                    Text("5 free thinks to start")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(white: 0.3))
                }
            }
            .padding(.bottom, 52)
        }
        .padding(.horizontal, 24)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                onComplete()
            }
        }
    }

    // MARK: - Helpers

    private func quizPill(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(selected ? .black : .white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .background(selected ? Color.white : Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func onboardingButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func requestNotificationPermission(completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    NotificationManager.shared.scheduleWeeklyNotification()
                }
                completion()
            }
        }
    }
}
