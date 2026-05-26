import SwiftUI
import UserNotifications

struct OnboardingView: View {
    var onComplete: () -> Void

    @StateObject private var video = OnboardingVideoController()
    @State private var currentScreen = 0
    #if DEBUG
    @State private var debugHideBackground = false
    #endif
    @State private var quiz1Selection: Int? = nil
    @State private var quiz2Selection: Int? = nil
    @State private var quiz3Selection: Int? = nil
    @State private var progress: CGFloat = 0
    @State private var brainReady = false
    @State private var selectedPlan: Int = 2

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            #if DEBUG
            if !debugHideBackground {
                VideoPlayerView(player: video.player)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            #else
            VideoPlayerView(player: video.player)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            #endif

            switch currentScreen {
            case 0:  screenOne.transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)), removal: .opacity))
            case 1:  screenTwo.transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)), removal: .opacity))
            case 2:  consentScreen.transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)), removal: .opacity))
            case 3:  screenQuiz1.transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)), removal: .opacity))
            case 4:  screenQuiz2.transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)), removal: .opacity))
            case 5:  screenQuiz3.transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)), removal: .opacity))
            case 6:  screenBuildingBrain.transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)), removal: .opacity))
            case 7:  screenHowItWorks.transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)), removal: .opacity))
            case 8:  screenNotifications.transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)), removal: .opacity))
            case 9:  screenBrainComplete.transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)), removal: .opacity))
            case 10: screenPaywall.transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)), removal: .opacity))
            case 11: screenDone.transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)), removal: .opacity))
            default: screenOne.transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)), removal: .opacity))
            }
        }
        .animation(.easeOut(duration: 1.0).delay(0.1), value: currentScreen)
        .onAppear { video.start() }
        #if DEBUG
        .overlay(alignment: .top) { debugNav }
        #endif
    }

    #if DEBUG
    private var debugNav: some View {
        GeometryReader { geo in
            let screen = UIScreen.main.bounds
            let safe   = geo.safeAreaInsets
            VStack(spacing: 6) {
                // Screen nav
                HStack(spacing: 0) {
                    Button {
                        if currentScreen > 0 { currentScreen -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 30)
                    }
                    Text("\(currentScreen + 1) / 12")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 48)
                    Button {
                        if currentScreen < 11 { currentScreen += 1 }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 30)
                    }
                }
                .background(.ultraThinMaterial.opacity(0.6))
                .clipShape(Capsule())

                // BG toggle + size info
                HStack(spacing: 10) {
                    Button {
                        debugHideBackground.toggle()
                    } label: {
                        Text(debugHideBackground ? "BG OFF" : "BG ON")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(debugHideBackground ? .yellow : .white.opacity(0.5))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(.ultraThinMaterial.opacity(0.6))
                            .clipShape(Capsule())
                    }
                    Text("\(Int(screen.width))×\(Int(screen.height))  T:\(Int(safe.top)) B:\(Int(safe.bottom))")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
        .frame(height: 70)
    }
    #endif

    // MARK: - Screen 0

    private var screenOne: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text("You already know\nwhat you should do.")
                .font(.custom("HelveticaNeue", size: 32))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineSpacing(32 * 0.3)
            Spacer().frame(height: 16)
            Text("You just need something\nto think it through with you.")
                .font(.custom("Poppins-Regular", size: 20))
                .foregroundColor(.white.opacity(0.45))
                .multilineTextAlignment(.leading)
                .lineSpacing(20 * 0.4)
            Spacer().frame(height: 88)
            onboardingButton("I'm ready") {
                video.playNextTransition {
                    withAnimation(.easeInOut(duration: 0.4)) { currentScreen = 1 }
                }
            }
            .padding(.bottom, 52)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Screen 1

    private var screenTwo: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 24)
            Text("This isn't advice.")
                .font(.custom("HelveticaNeue", size: 32))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            Spacer().frame(height: 20)
            Text("It's your situation,\nrun through thousands\nof possible outcomes.\nThen handed back to you.")
                .font(.custom("Poppins-Regular", size: 20))
                .foregroundColor(.white.opacity(0.45))
                .multilineTextAlignment(.leading)
                .lineSpacing(20 * 0.5)
            Spacer()
            onboardingButton("That's different") {
                video.playNextTransition { currentScreen = 2 }
            }
                .padding(.bottom, 52)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Screen 2 — Consent

    private var consentScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 24)
            Text("before we begin.")
                .font(.custom("HelveticaNeue", size: 32))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
            Text("your thinks are processed by Claude AI.\nwhat you share leaves your device\nto generate a response.")
                .font(.custom("Poppins-Regular", size: 18))
                .foregroundColor(.white.opacity(0.45))
                .lineSpacing(6)
                .padding(.horizontal, 32)
                .padding(.bottom, 12)
            Text("we don't store your thinks.\nno servers. no profiles. no ads.\neverything stays between you and the brain.")
                .font(.custom("Poppins-Regular", size: 18))
                .foregroundColor(.white.opacity(0.45))
                .lineSpacing(6)
                .padding(.horizontal, 32)
                .padding(.bottom, 12)
            Text("the brain provides perspective.\nnot instructions.\nall decisions remain entirely yours.")
                .font(.custom("Poppins-Regular", size: 18))
                .foregroundColor(.white.opacity(0.45))
                .lineSpacing(6)
                .padding(.horizontal, 32)
            Spacer()
            Button(action: {
                UserDefaults.standard.set(true, forKey: "hasGivenAIConsent")
                video.playNextTransition { currentScreen = 3 }
            }) {
                Text("I understand and agree")
                    .font(.custom("HelveticaNeue", size: 17))
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
                        .font(.custom("Poppins-Regular", size: 13))
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
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .tracking(1.5)
                Spacer().frame(height: 32)
                Text("how often do you face decisions\nyou can't stop thinking about?")
                    .font(.custom("HelveticaNeue", size: 26))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(26 * 0.3)
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
            onboardingButton("continue") {
                video.playNextTransition { currentScreen = 4 }
            }
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
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .tracking(1.5)
                Spacer().frame(height: 32)
                Text("what do you struggle\nwith most?")
                    .font(.custom("HelveticaNeue", size: 26))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(26 * 0.3)
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
            onboardingButton("continue") {
                video.playNextTransition { currentScreen = 5 }
            }
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
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .tracking(1.5)
                Spacer().frame(height: 32)
                Text("when do you usually\nface these moments?")
                    .font(.custom("HelveticaNeue", size: 26))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(26 * 0.3)
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
            onboardingButton("continue") {
                video.playNextTransition { currentScreen = 6 }
            }
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
                    .font(.custom("HelveticaNeue", size: 32))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .id(brainReady)
                    .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)), removal: .opacity))

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
                        .font(.custom("Poppins-Regular", size: 20))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)), removal: .opacity))
                }
            }
            .padding(.horizontal, 30)
            Spacer()
        }
        .onAppear {
            progress = 0
            brainReady = false
            withAnimation(.linear(duration: 2)) { progress = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.4)) { brainReady = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { currentScreen = 7 }
        }
    }

    // MARK: - Screen 7 — How It Works

    private var screenHowItWorks: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 0) {
                Text("how it works.")
                    .font(.custom("HelveticaNeue", size: 32))
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
            onboardingButton("I'm ready") {
                video.playNextTransition { currentScreen = 8 }
            }
                .padding(.bottom, 52)
        }
        .padding(.horizontal, 24)
    }

    private func howItWorksBlock(number: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(number)
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(Color(white: 0.3))
            Text(title)
                .font(.custom("HelveticaNeue", size: 22))
                .foregroundColor(.white)
            Text(body)
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundColor(.white.opacity(0.45))
                .lineSpacing(15 * 0.5)
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
                    .font(.custom("HelveticaNeue", size: 26))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(26 * 0.3)
                Spacer().frame(height: 20)
                Text("let the brain find you\nwhen something's sitting with you.")
                    .font(.custom("Poppins-Regular", size: 20))
                    .foregroundColor(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .lineSpacing(20 * 0.5)
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
                        .font(.custom("Poppins-Regular", size: 16))
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

    // MARK: - Screen 9 — Brain Complete

    private var screenBrainComplete: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 18) {
                Text("your brain\nis calibrated.")
                    .font(.custom("HelveticaNeue", size: 34))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(34 * 0.25)
                Text("personalised to the way you think.")
                    .font(.custom("Poppins-Regular", size: 18))
                    .foregroundColor(.white.opacity(0.38))
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeInOut(duration: 0.4)) { currentScreen = 10 }
            }
        }
    }

    // MARK: - Screen 10 — Onboarding Paywall

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
                        index: 0, title: "FREE", price: nil,
                        subtitle: "5 thinks to start", detail: "try the brain",
                        rightBadge: "current", isProBadge: false, isFree: true
                    )
                    onboardingPlanCard(
                        index: 1, title: "CORE", price: "$39.99",
                        subtitle: "500 thinks · 6 months", detail: "everything unlocked",
                        rightBadge: nil, isProBadge: false, isFree: false
                    )
                    onboardingPlanCard(
                        index: 2, title: "PRO", price: "$99.99/year",
                        subtitle: "unlimited thinks", detail: "chat + full memory",
                        rightBadge: nil, isProBadge: true, isFree: false
                    )
                }
                .padding(.horizontal, 24)

                if selectedPlan == 2 {
                    VStack(spacing: 16) {
                        Text("No Payment Due Today")
                            .font(.custom("Poppins-Regular", size: 13))
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
                    .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)), removal: .opacity))
                }

                Spacer().frame(height: 28)

                Group {
                    if selectedPlan == 0 {
                        Button { currentScreen = 11 } label: {
                            Text("continue for free")
                                .font(.custom("HelveticaNeue", size: 17))
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
                            currentScreen = 11
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

                HStack(spacing: 16) {
                    Button { } label: {
                        Text("restore purchase")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(Color(white: 0.3))
                    }
                    Text("·").foregroundColor(Color(white: 0.15))
                    Button {
                        if let url = URL(string: "https://creative-sailfish-dc6.notion.site/Terms-and-conditions-3647cd351f5b8000b482d1062d00f0ad") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("terms")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(Color(white: 0.3))
                    }
                    Text("·").foregroundColor(Color(white: 0.15))
                    Button {
                        if let url = URL(string: "https://creative-sailfish-dc6.notion.site/privacy-policy-3647cd351f5b807b9021d48d42a71a0b") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("privacy")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(Color(white: 0.3))
                    }
                }
                .padding(.bottom, 8)

                if selectedPlan == 2 {
                    Text("3 days free, then $99.99/year. Cancel anytime.")
                        .font(.custom("Poppins-Regular", size: 11))
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
        index: Int, title: String, price: String?,
        subtitle: String, detail: String, rightBadge: String?,
        isProBadge: Bool, isFree: Bool
    ) -> some View {
        let isSelected = selectedPlan == index
        return Button { selectedPlan = index } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.custom("HelveticaNeue", size: 15))
                            .foregroundColor(isFree ? Color(white: 0.3) : .white)
                        if isProBadge {
                            Text("3 DAYS FREE")
                                .font(.custom("Poppins-Regular", size: 10))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6).padding(.vertical, 3)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    Text(subtitle)
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(isFree ? Color(white: 0.3) : Color(white: 0.4))
                    Text(detail)
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(isFree ? Color(white: 0.3) : Color(white: 0.4))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    if let price = price {
                        Text(price)
                            .font(.custom("HelveticaNeue", size: 14))
                            .foregroundColor(.white)
                    }
                    if let badge = rightBadge {
                        Text(badge)
                            .font(.custom("Poppins-Regular", size: 11))
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
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(Color(white: 0.4))
                .frame(width: 44, alignment: .leading)
            Text(text)
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(Color(white: 0.6))
            Spacer()
        }
    }

    // MARK: - Screen 11 — Done

    private var screenDone: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 0) {
                Text("you're ready.")
                    .font(.custom("HelveticaNeue", size: 32))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Spacer().frame(height: 20)
                Text("bring it something real.")
                    .font(.custom("Poppins-Regular", size: 22))
                    .foregroundColor(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
            }
            Spacer()
            VStack(spacing: 12) {
                onboardingButton("let's go") { onComplete() }
                if selectedPlan == 0 {
                    Text("5 free thinks to start")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(Color(white: 0.3))
                }
            }
            .padding(.bottom, 52)
        }
        .padding(.horizontal, 24)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { onComplete() }
        }
    }

    // MARK: - Helpers

    private func quizPill(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Poppins-Regular", size: 16))
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
                .font(.custom("HelveticaNeue", size: 17))
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
                if granted { NotificationManager.shared.scheduleWeeklyNotification() }
                completion()
            }
        }
    }
}
