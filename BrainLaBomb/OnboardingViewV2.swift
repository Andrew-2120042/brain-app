import SwiftUI
import UserNotifications
import PostHog
import StoreKit

// MARK: - OnboardingViewV2
// One unified space. Every thought types in at the same anchor.
// History fades upward. No pages. No screen switches.

struct NumericIntroParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let targetPosition: CGPoint
    let isBracketCell: Bool
    var hex: String
    var currentOpacity: Double = 0
    var currentScale: CGFloat = 1.0
}

// Proportional bracket: matches the digit-bracket (4 cells wide × 14 rows tall).
// Horizontal bars = 1/14 of height. Vertical bar = 1/2 of width.
struct BracketShape: Shape {
    enum Side { case left, right }
    let side: Side

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let barH = h / 14.0
        let vertW = w / 2.0

        p.addRect(CGRect(x: 0, y: 0, width: w, height: barH))
        p.addRect(CGRect(x: 0, y: h - barH, width: w, height: barH))
        switch side {
        case .left:
            p.addRect(CGRect(x: 0, y: 0, width: vertW, height: h))
        case .right:
            p.addRect(CGRect(x: w - vertW, y: 0, width: vertW, height: h))
        }
        return p
    }
}

struct OnboardingViewV2: View {
    var viewModel: AppViewModel
    var onComplete: () -> Void

    @State private var step = 0
    @State private var history: [V2MemoryEntry] = []
    @State private var typedText = ""
    @State private var contentVisible = false
    @State private var isTransitioning = false

    @State private var userName = ""
    @State private var userAge = ""
    @State private var ageSubmitted = false
    @State private var quizSelections: [Int?] = Array(repeating: nil, count: 6)
    @State private var multiSelections6: Set<Int> = []
    @State private var multiSelections7: Set<Int> = []
    @State private var multiSelections8: Set<Int> = []
    @State private var step6ContinueVisible = false
    @State private var step7ContinueVisible = false
    @State private var step8ContinueVisible = false
    @State private var step6Loading = false
    @State private var loadingPulse = false
    @State private var customAnswer = ""
    @State private var step10ShowTextField = false
    @State private var patternRevealPhase: Int = 0
    @State private var patternRevealDismissOpacity: Double = 1
    @State private var patternRevealContent: String = ""
    @State private var patternRevealLoaded: Bool = false
    @State private var patternRevealFailed: Bool = false
    @State private var patternDescriptionPhase: Int = 0
    @State private var patternContentAnimating: Bool = false
    @State private var showBrandIntro: Bool = true
    @State private var brandIntroPhase: Int = 0
    @State private var bracketWordOpacity: Double = 0
    @State private var typedBracketWord: String = ""
    @State private var letterOpacities: [Double] = Array(repeating: 1.0, count: 7)
    @State private var leftBracketOpacity: Double = 0
    @State private var rightBracketOpacity: Double = 0
    @State private var leftBracketX: CGFloat = -80
    @State private var rightBracketX: CGFloat = 80
    @State private var brandLogoScale: CGFloat = 1.0
    @State private var brandLogoYOffset: CGFloat = 0
    @State private var selectedPlan: Int = 0
    @State private var buildProgress: CGFloat = 0
    @State private var buildDone = false
    @State private var showPurchaseError = false
    @State private var purchaseErrorMessage = ""
    @State private var showDocs = false
    @State private var docsTab = 0
    @State private var typingGeneration = 0
    @State private var paywallProPrice = "$99.99"
    @State private var paywallCorePrice = "$59.99"
    @State private var paywallProMonthly = "$8.33"
    @State private var paywallCoreMonthly = "$10.00"
    @State private var showOnboardingConfirmation = false
    @State private var onboardingConfirmationTier: AppTier = .core
    @State private var showDownsell = false

    @FocusState private var nameFieldFocused: Bool
    @FocusState private var ageFieldFocused: Bool

    @AppStorage("useNumericIntro") private var useNumericIntro = false
    @State private var numericParticles: [NumericIntroParticle] = []

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var blackPhase: Int = 0
    @State private var badNewsPhase: Int = 0
    @State private var badNewsDismissOpacity: Double = 1
    @State private var goodNewsPhase: Int = 0
    @State private var goodNewsDismissOpacity: Double = 1
    @State private var rollingPhrase: Int = 0
    @State private var goodNewsRolling = false
    @State private var badNewsQuotePhrase: Int = 0
    @State private var displayedMomentsNumber: String = "000,000"
    @State private var goodNewsVariant: Int = 0
    @State private var badNewsQuoteCycling: Bool = false
    @State private var howWeHelpPhase: Int = 0
    @State private var nudgePhase: Int = 0
    @State private var featuresPhase: Int = 0
    @State private var youreReadyPhase: Int = 0

    // Step 17 — demo think (live verdict card)
    @State private var demoResult: DecisionResult? = nil
    @State private var demoCardOffset: CGFloat = 0
    @State private var demoContinueVisible: Bool = false
    @State private var demoLayoutIndex: Int = 0
    @State private var demoThinkID: UUID = UUID()
    @State private var demoCardAngle: Double = 0
    @State private var demoTiltX: Double = 0
    @State private var demoDragBase: Double = 0
    @State private var demoDragStarted: Bool = false
    @State private var demoBackScrolling: Bool = false
    @State private var demoInput: String = ""
    @State private var demoInputVisible: Bool = true
    @State private var demoThinking: Bool = false
    @State private var demoFallback: Bool = false
    @State private var demoResolved: Bool = false
    @State private var demoFollowUpQ: String = ""
    @State private var demoShowFollowUp: Bool = false
    @State private var demoShowIntro: Bool = true
    @State private var demoIntroPhase: Int = 0
    @State private var demoPostActive: Bool = false
    @State private var demoPostPhase: Int = 0
    @State private var demoPostMessage: Int = 1
    @State private var demoBeatTappable: Bool = false
    @State private var demoTailoredActive: Bool = false
    @State private var demoTailoredPhase: Int = 0
    @State private var demoReviewActive: Bool = false
    @State private var demoReviewPhase: Int = 0
    @State private var demoReviewAdvanced: Bool = false
    @State private var demoThinkCompleted: Bool = false
    @State private var demoShowChat: Bool = false
    @State private var demoDebugCard: Bool = false
    @State private var demoDebugChat: Bool = false
    @State private var demoDebugReview: Bool = false
    @FocusState private var demoInputFocused: Bool

    private let anchorTexts = [
        "You already know\nwhat you should do.",                            // 0
        "This isn't advice.",                                               // 1
        "Before we begin.",                                                 // 2
        "What should I call you?",                                          // 3
        "How old are you?",                                                 // 4
        "How often do you face decisions\nyou can't stop thinking about?",  // 5
        "What do you struggle\nwith most?",                                 // 6
        "When do you usually\nface these moments?",                         // 7
        "What stops you from trusting\nyour instincts?",                    // 8
        "How long have you been sitting\nwith your most recent big decision?", // 9
        "Right now — what best describes\nwhere you are?",                  // 10
        "Building your brain.",                                             // 11
        "",                                                                 // 12 full-screen black transition
        "",                                                                 // 13 full-screen pattern reveal
        "",                                                                 // 14 full-screen bad news
        "",                                                                 // 15 full-screen good news
        "",                                                                 // 16 full-screen how we help
        "",                                                                 // 17 full-screen demo think
        "",                                                                 // 18 full-screen features/value
        "",                                                                 // 19 full-screen paywall
        "",                                                                 // 20 full-screen nudge/notifications
        "You're ready."                                                     // 21
    ]

    private let quizReflections: [[String]] = [
        // Step 5 — frequency
        ["That means you're always carrying something.",
         "Enough to know the feeling well.",
         "But when it hits it hits hard.",
         "The ones that matter always feel that way."],
        // Step 6 — struggle (Haiku-generated, these are fallbacks)
        ["Harder than it sounds. Most people never figure it out.",
         "You already know the answer. You're building the case against it.",
         "Emotion isn't the enemy. Confusion is.",
         "You're deciding for an audience that isn't watching."],
        // Step 7 — when
        ["That's when the real thinking happens.",
         "When the stakes are highest the noise is loudest.",
         "The hardest decisions always involve someone else.",
         "The two things that were never supposed to mix."],
        // Step 8 — why can't you trust your instincts
        ["Being wrong once is survivable.\nStaying stuck forever isn't.",
         "You're deciding for an audience\nthat isn't watching as closely as you think.",
         "Commitment isn't the problem.\nNot knowing if it's the right thing to commit to is.",
         "Not knowing why you can't trust yourself\nis the most honest answer here."],
        // Step 9 — how long
        ["Still fresh. The noise hasn't peaked yet.",
         "Long enough that it's starting to feel permanent.\nIt isn't.",
         "Months of carrying something\nthat deserves an answer.",
         "That's not indecision.\nThat's a decision That's been waiting\nlonger than it should have."],
        // Step 10 — where are you
        ["Both options feel right\nbecause you haven't run them forward yet.",
         "Knowing and doing are separated\nby exactly one thing. Trust.",
         "That's the most honest place to start from.",
         "Processing and deciding aren't the same thing.\nYou need both.",
         "Whatever it is — you brought it here.\nThat's enough to start."]
    ]

    private let quizOptions: [[String]] = [
        // Step 5
        ["Constantly — almost every day",
         "Often — a few times a week",
         "Sometimes — once in a while",
         "Rarely — but when I do they're heavy"],
        // Step 6
        ["Knowing what I actually want",
         "Overthinking every angle",
         "Being too emotional to think clearly",
         "Caring too much what others think"],
        // Step 7
        ["Late at night when everything gets loud",
         "During big life changes",
         "When relationships get complicated",
         "When work and life collide"],
        // Step 8
        ["Fear of being wrong",
         "Fear of what others will think",
         "Fear of commitment",
         "I don't know — That's the problem"],
        // Step 9
        ["A few days",
         "A few weeks",
         "Months",
         "Honestly I can't remember when it started"],
        // Step 10
        ["Stuck between two options",
         "I know what I should do but can't do it",
         "Completely lost — no idea what I want",
         "Something happened and I need to process it",
         "Something else — let me type it"]
    ]

    init(viewModel: AppViewModel, onComplete: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onComplete = onComplete
        if UserDefaults.standard.bool(forKey: "test_jumpToPaywallStep") {
            UserDefaults.standard.removeObject(forKey: "test_jumpToPaywallStep")
            _showBrandIntro = State(initialValue: false)
            _step = State(initialValue: 19)
            return
        }
        let saved = UserDefaults.standard.object(forKey: Constants.onboardingProgressKey) as? Int ?? 0
        if saved > 0 {
            _showBrandIntro = State(initialValue: false)
            _step = State(initialValue: min(saved, 19))
        }
    }

    var body: some View {
        ZStack {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Color.black.ignoresSafeArea()

                // ── Memory zone ─────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 12) {
                    Spacer(minLength: 0)
                    ForEach(Array(history.suffix(6))) { entry in
                        V2MemoryEntryView(entry: entry)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 0, maxHeight: geo.size.height * 0.44)
                .padding(.horizontal, 28)
                .clipped()
                .allowsHitTesting(false)
                .animation(.spring(response: 0.42, dampingFraction: 1.0), value: history.count)

                // ── Active zone ─────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 0) {
                    Text(typedText)
                        .font(.custom("HelveticaNeue", size: step <= 1 ? 22 : 20))
                        .foregroundColor(.white)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)

                    if contentVisible {
                        stepContent(geo: geo)
                            .transition(.opacity.animation(.easeIn(duration: 0.22)))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 22)
                .offset(y: geo.size.height * 0.44)

                // ── Tap-to-continue overlay for intros (step 0 & 1) ──────────
                if (step == 0 || step == 1) && contentVisible {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard !isTransitioning else { return }
                            let idx = step
                            advance(q: anchorTexts[idx], a: "")
                        }
                        .zIndex(5)
                }

                // ── Full-screen special steps ────────────────────────────────
                // Persistent black underlay prevents Q&A content showing through
                // during opacity transitions between special screens
                if step >= 12 && step <= 21 {
                    Color.black.ignoresSafeArea().zIndex(9)
                }
                if step == 12 { blackTransitionView.transition(.opacity).zIndex(10) }
                if step == 13 { patternRevealView.transition(.opacity).zIndex(10) }
                if step == 14 { badNewsView.transition(.opacity).zIndex(10) }
                if step == 15 { goodNewsView.transition(.opacity).zIndex(10) }
                if step == 16 { howWeHelpView.transition(.opacity).zIndex(10) }
                if step == 17 { demoThinkView.transition(.opacity).zIndex(10) }
                if step == 18 { featuresView.transition(.opacity).zIndex(10) }
                if step == 19 { paywallView.transition(.opacity).zIndex(10) }
                if step == 20 { nudgeView.transition(.opacity).zIndex(10) }
                if step == 21 { youreReadyView.transition(.opacity).zIndex(10) }
            }
            .animation(.easeInOut(duration: 0.45), value: step >= 12 && step <= 21)
        }
        .opacity(showBrandIntro ? 0 : 1)

        // Persistent brackets — live above everything, animate into final top position
        #if DEBUG
        Button {
            typedBracketWord = ""
            bracketWordOpacity = 0
            letterOpacities = Array(repeating: 1.0, count: 7)
            leftBracketOpacity = 0
            rightBracketOpacity = 0
            leftBracketX = -80
            rightBracketX = 80
            brandLogoScale = 1.0
            brandLogoYOffset = 0
            showBrandIntro = true
        } label: {
            ZStack {
                Color.clear.frame(width: 80, height: 80)
                HStack(spacing: 0) {
                    ForEach(Array(typedBracketWord.enumerated()), id: \.offset) { i, char in
                        Text(String(char))
                            .font(.custom("HelveticaNeue-Light", size: 20))
                            .foregroundColor(.white)
                            .opacity(i < letterOpacities.count ? letterOpacities[i] : 1.0)
                    }
                }
                .opacity(bracketWordOpacity)
                if useNumericIntro {
                    BracketShape(side: .left)
                        .fill(Color.white)
                        .frame(width: 24, height: 70)
                        .opacity(leftBracketOpacity)
                        .offset(x: leftBracketX)
                    BracketShape(side: .right)
                        .fill(Color.white)
                        .frame(width: 24, height: 70)
                        .opacity(rightBracketOpacity)
                        .offset(x: rightBracketX)
                } else {
                    Text("[")
                        .font(.custom("HelveticaNeue-Light", size: 32))
                        .foregroundColor(.white)
                        .opacity(leftBracketOpacity)
                        .offset(x: leftBracketX)
                    Text("]")
                        .font(.custom("HelveticaNeue-Light", size: 32))
                        .foregroundColor(.white)
                        .opacity(rightBracketOpacity)
                        .offset(x: rightBracketX)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(brandLogoScale)
        .offset(y: brandLogoYOffset)
        .opacity(step == 19 ? 0 : 1)
        .zIndex(200)
        #else
        ZStack {
            HStack(spacing: 0) {
                ForEach(Array(typedBracketWord.enumerated()), id: \.offset) { i, char in
                    Text(String(char))
                        .font(.custom("HelveticaNeue-Light", size: 20))
                        .foregroundColor(.white)
                        .opacity(i < letterOpacities.count ? letterOpacities[i] : 1.0)
                }
            }
            .opacity(bracketWordOpacity)
            if useNumericIntro {
                BracketShape(side: .left)
                    .fill(Color.white)
                    .frame(width: 24, height: 70)
                    .opacity(leftBracketOpacity)
                    .offset(x: leftBracketX)
                BracketShape(side: .right)
                    .fill(Color.white)
                    .frame(width: 24, height: 70)
                    .opacity(rightBracketOpacity)
                    .offset(x: rightBracketX)
            } else {
                Text("[")
                    .font(.custom("HelveticaNeue-Light", size: 32))
                    .foregroundColor(.white)
                    .opacity(leftBracketOpacity)
                    .offset(x: leftBracketX)
                Text("]")
                    .font(.custom("HelveticaNeue-Light", size: 32))
                    .foregroundColor(.white)
                    .opacity(rightBracketOpacity)
                    .offset(x: rightBracketX)
            }
        }
        .allowsHitTesting(false)
        .scaleEffect(brandLogoScale)
        .offset(y: brandLogoYOffset)
        .opacity(step == 19 ? 0 : 1)
        .zIndex(200)
        #endif

        if showBrandIntro {
            brandIntroView
                .transition(.opacity)
                .zIndex(100)
        }

        #if DEBUG
        if !viewModel.hideDebugUI {
            VStack(spacing: 10) {
                Button("→ home") { onComplete() }
                Button("→ paywall") { showBrandIntro = false; step = 19 }
                Button("→ pattern reveal") { showBrandIntro = false; step = 13 }
                Button("→ how we help") { showBrandIntro = false; step = 16 }
                Button("→ try it now") { demoDebugCard = false; demoDebugChat = false; demoDebugReview = false; showBrandIntro = false; step = 17 }
                Button("→ demo card") { demoDebugCard = true; demoDebugChat = false; demoDebugReview = false; showBrandIntro = false; step = 17 }
                Button("→ chat") { demoDebugChat = true; demoDebugCard = false; demoDebugReview = false; showBrandIntro = false; step = 17 }
                Button("→ review") { demoDebugReview = true; demoDebugCard = false; demoDebugChat = false; showBrandIntro = false; step = 17 }
            }
            .font(.custom("HelveticaNeue", size: 11))
            .foregroundColor(Color(white: 0.28))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 52)
            .allowsHitTesting(true)
            .zIndex(300)
        }
        #endif

        // Chat interface — presented as a fade overlay (not a slide-up cover),
        // seeded with the user's question + verdict
        if demoShowChat, let result = demoResult {
            ChatView(
                originalQuestion: demoInput,
                decisionResult: result,
                viewModel: viewModel,
                thinkID: demoThinkID,
                existingMessages: [],
                onMessagesUpdated: { _ in },
                onNewThink: nil,
                showNextInsteadOfClose: true,
                onClose: {
                    withAnimation(.easeInOut(duration: 0.4)) { demoShowChat = false }
                    startDemoFinalBeat()
                }
            )
            .transition(.opacity)
            .zIndex(400)
        }

        }
        .animation(.easeInOut(duration: 0.5), value: showBrandIntro)
        .onChange(of: showBrandIntro) { newValue in
            if !newValue { startTyping() }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                PostHogSDK.shared.capture("onboarding_abandoned", properties: [
                    "step": step,
                    "step_name": onboardingStepName(step)
                ])
            }
        }
        .onAppear {
            if !showBrandIntro { startTyping() }
        }
        .sheet(isPresented: $showDocs) {
            DocsView(initialTab: docsTab)
        }
        .fullScreenCover(isPresented: $showDownsell) {
            DownsellWeeklyView(viewModel: viewModel) {
                showDownsell = false
                if !viewModel.hasActiveEntitlement {
                    NotificationManager.shared.scheduleReEngagementNotifications()
                }
                advanceNoHistory()
            }
        }
    }

    // MARK: - Step content

    @ViewBuilder
    private func stepContent(geo: GeometryProxy) -> some View {
        switch step {
        case 0:  step0
        case 1:  step1
        case 2:  step2
        case 3:  step3
        case 4:  step4Age
        case 5:  stepQuiz(index: 0)
        case 6:  step6MultiQuiz
        case 7:  step7MultiQuiz
        case 8:  step8MultiQuiz
        case 9:  stepQuiz(index: 4)
        case 10: step10WhereAreYou
        case 11: step8
        default: EmptyView()
        }
    }

    // MARK: Step 0 — intro

    private var step0: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 10)
            Text("You just need something\nto think it through with you.")
                .font(.custom("Poppins-Regular", size: 17))
                .foregroundColor(.white.opacity(0.40))
                .lineSpacing(6)
            Spacer().frame(height: 28)
            Text("Tap to continue")
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(.white.opacity(0.25))
        }
    }

    // MARK: Step 1 — intro 2

    private var step1: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 10)
            Text("It's your situation,\nrun through thousands of possible outcomes.\nThen handed back to you.")
                .font(.custom("Poppins-Regular", size: 17))
                .foregroundColor(.white.opacity(0.40))
                .lineSpacing(6)
            Spacer().frame(height: 28)
            Text("Tap to continue")
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(.white.opacity(0.25))
        }
    }

    // MARK: Step 2 — consent

    private var step2: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 12)
                Text("Your responses are sent to Anthropic's Claude AI to generate your decision results. No data is stored or used for training.")
                    .font(.custom("Poppins-Regular", size: 17))
                    .foregroundColor(.white.opacity(0.40))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer().frame(height: 30)
                v2Button("I understand and agree") {
                    UserDefaults.standard.set(true, forKey: "hasGivenAIConsent")
                    advance(q: anchorTexts[2], a: "Agreed")
                }
                Spacer().frame(height: 10)
                HStack(spacing: 24) {
                    Button {
                        if let url = URL(string: "https://creative-sailfish-dc6.notion.site/privacy-policy-3647cd351f5b807b9021d48d42a71a0b?source=copy_link") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Privacy")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.40))
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button {
                        if let url = URL(string: "https://creative-sailfish-dc6.notion.site/Terms-and-conditions-3647cd351f5b8000b482d1062d00f0ad?source=copy_link") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Terms")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.40))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Step 3 — name

    private var step3: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 12)
            ZStack(alignment: .leading) {
                if userName.isEmpty {
                    Text("Your name")
                        .font(.custom("HelveticaNeue", size: 21))
                        .foregroundColor(.white.opacity(0.20))
                }
                TextField("", text: $userName)
                    .font(.custom("HelveticaNeue", size: 21))
                    .foregroundColor(.white)
                    .tint(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .submitLabel(.continue)
                    .focused($nameFieldFocused)
                    .onSubmit { submitName() }
            }
            .padding(.vertical, 12)
            .overlay(
                Rectangle().fill(Color.white.opacity(0.16)).frame(height: 1),
                alignment: .bottom
            )
            Spacer().frame(height: 28)
            v2Button("Continue") { submitName() }
                .opacity(userName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.28 : 1)
                .disabled(userName.trimmingCharacters(in: .whitespaces).isEmpty || isTransitioning)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                nameFieldFocused = true
            }
        }
    }

    private func submitName() {
        let name = userName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !isTransitioning else { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        advance(q: anchorTexts[3], a: name)
    }

    // MARK: Step 4 — age

    private var step4Age: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 12)
            ZStack(alignment: .leading) {
                if userAge.isEmpty {
                    Text("Your age")
                        .font(.custom("HelveticaNeue", size: 21))
                        .foregroundColor(.white.opacity(0.20))
                }
                TextField("", text: $userAge)
                    .font(.custom("HelveticaNeue", size: 21))
                    .foregroundColor(.white)
                    .tint(.white)
                    .keyboardType(.numberPad)
                    .focused($ageFieldFocused)
                    .onChange(of: userAge) { newVal in
                        let digits = String(newVal.filter { $0.isNumber }.prefix(2))
                        if digits != newVal { userAge = digits }
                    }
            }
            .padding(.vertical, 12)
            .overlay(
                Rectangle().fill(Color.white.opacity(0.16)).frame(height: 1),
                alignment: .bottom
            )
            if ageTooLow {
                Text("This app is for ages 13 and above.")
                    .font(.custom("HelveticaNeue", size: 13))
                    .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4).opacity(0.85))
                    .padding(.top, 10)
                    .transition(.opacity)
            }
            Spacer().frame(height: 28)
            v2Button("Continue") { submitAge() }
                .opacity(ageIsValid ? 1 : 0.28)
                .disabled(!ageIsValid || isTransitioning || ageSubmitted)
        }
        .animation(.easeInOut(duration: 0.2), value: ageTooLow)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                ageFieldFocused = true
            }
        }
    }

    private var ageIsValid: Bool {
        guard let age = Int(userAge) else { return false }
        return age >= 13 && age <= 99
    }

    private var ageTooLow: Bool {
        guard userAge.count == 2, let age = Int(userAge) else { return false }
        return age < 13
    }

    private var personYearsLabel: String {
        switch quizSelections[0] {
        case 0: return "9 years."
        case 1: return "7 years."
        case 2: return "4 years."
        case 3: return "2 years."
        default: return "7 years."
        }
    }

    private var personYearsNumber: String {
        switch quizSelections[0] {
        case 0: return "9"
        case 1: return "7"
        case 2: return "4"
        case 3: return "2"
        default: return "7"
        }
    }

    private var personMomentsLabel: String {
        switch quizSelections[0] {
        case 0: return "742,000"
        case 1: return "512,000"
        case 2: return "292,000"
        case 3: return "175,000"
        default: return "512,000"
        }
    }

    private var ageReflectionText: String {
        if let age = Int(userAge.trimmingCharacters(in: .whitespaces)) {
            switch age {
            case ..<20:
                return "young enough that most of your biggest decisions are still ahead."
            case 20...25:
                return "the age where everything feels like it matters permanently. it usually doesn't. but some of it does."
            case 26...30:
                return "old enough to know what you want. still figuring out how to get there."
            case 31...40:
                return "you've made enough decisions to know that clarity is rarer than you'd like."
            default:
                return "you've been here long enough to know the answer was usually right the first time."
            }
        }
        return "the age where everything feels like it matters permanently. it usually doesn't. but some of it does."
    }

    private func submitAge() {
        let ageStr = userAge.trimmingCharacters(in: .whitespaces)
        guard ageIsValid, !isTransitioning, !ageSubmitted else { return }
        ageSubmitted = true
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        let reflection = ageReflectionText

        isTransitioning = true
        contentVisible = false
        var updated = history
        for i in 0..<updated.count { updated[i].age += 1 }
        updated.append(V2MemoryEntry(question: anchorTexts[4], answer: ageStr, age: 0))
        history = updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { typedText = "" }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            isTransitioning = false
            typingGeneration += 1
            let gen = typingGeneration
            let chars = Array(reflection)
            for (i, char) in chars.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.022) {
                    guard typingGeneration == gen else { return }
                    typedText.append(char)
                    if i == chars.count - 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            guard typingGeneration == gen else { return }
                            advance(q: reflection, a: "")
                        }
                    }
                }
            }
        }
    }

    // MARK: Steps 5, 8, 9 — single-select quiz

    private func stepQuiz(index: Int) -> some View {
        let sel = Binding<Int?>(
            get: { quizSelections[index] },
            set: { quizSelections[index] = $0 }
        )
        return VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 14)
            VStack(spacing: 10) {
                ForEach(Array(quizOptions[index].enumerated()), id: \.offset) { i, option in
                    v2Pill(option, selected: sel.wrappedValue == i) {
                        guard !isTransitioning else { return }
                        sel.wrappedValue = i
                        let q = anchorTexts[step]
                        let a = quizOptions[index][i]
                        let reflection = quizReflections[index][i]

                        isTransitioning = true
                        contentVisible = false
                        var updated = history
                        for j in 0..<updated.count { updated[j].age += 1 }
                        updated.append(V2MemoryEntry(question: q, answer: a, age: 0))
                        history = updated
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { typedText = "" }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                            isTransitioning = false
                            typingGeneration += 1
                            let gen = typingGeneration
                            let chars = Array(reflection)
                            for (k, char) in chars.enumerated() {
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(k) * 0.022) {
                                    guard typingGeneration == gen else { return }
                                    typedText.append(char)
                                    if k == chars.count - 1 {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                            guard typingGeneration == gen else { return }
                                            advance(q: reflection, a: "")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Step 6 — multiple select, Haiku reflection

    private var step6MultiQuiz: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 14)
            if step6Loading {
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.white.opacity(loadingPulse ? 0.6 : 0.18))
                            .frame(width: 6, height: 6)
                            .animation(
                                .easeInOut(duration: 0.55)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.18),
                                value: loadingPulse
                            )
                    }
                }
                .padding(.top, 4)
                .onAppear { loadingPulse = true }
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(quizOptions[1].enumerated()), id: \.offset) { i, option in
                        v2Pill(option, selected: multiSelections6.contains(i)) {
                            guard !isTransitioning, !step6Loading else { return }
                            if multiSelections6.contains(i) {
                                multiSelections6.remove(i)
                            } else if multiSelections6.count < 4 {
                                multiSelections6.insert(i)
                            }
                            step6ContinueVisible = true
                        }
                    }
                }
                Text("You can select multiple answers")
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(Color(white: 0.35))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                if step6ContinueVisible {
                    Spacer().frame(height: 16)
                    v2Button("Continue") { handleStep6Continue() }
                        .disabled(multiSelections6.isEmpty)
                        .opacity(multiSelections6.isEmpty ? 0.28 : 1)
                        .transition(.opacity.animation(.easeIn(duration: 0.3)))
                }
            }
        }
    }

    private func handleStep6Continue() {
        guard !isTransitioning, !step6Loading, !multiSelections6.isEmpty else { return }

        let priorityIdx = multiSelections6.min() ?? 0
        quizSelections[1] = priorityIdx

        let q = anchorTexts[6]
        let selectedLabels = multiSelections6.sorted().map { quizOptions[1][$0] }
        let answerText = selectedLabels.joined(separator: " + ")
        let fallbackReflection = quizReflections[1][priorityIdx]

        step6Loading = true
        loadingPulse = false

        Task {
            do {
                let reflection = try await APIClient.shared.generateOnboardingReflection(selections: selectedLabels)
                await MainActor.run {
                    step6Loading = false
                    showReflectionAndAdvance(q: q, a: answerText, reflection: reflection)
                }
            } catch {
                await MainActor.run {
                    step6Loading = false
                    showReflectionAndAdvance(q: q, a: answerText, reflection: fallbackReflection)
                }
            }
        }
    }

    // MARK: Step 7 — multiple select, priority reflection

    private var step7MultiQuiz: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 14)
            VStack(spacing: 10) {
                ForEach(Array(quizOptions[2].enumerated()), id: \.offset) { i, option in
                    v2Pill(option, selected: multiSelections7.contains(i)) {
                        guard !isTransitioning else { return }
                        if multiSelections7.contains(i) {
                            multiSelections7.remove(i)
                        } else if multiSelections7.count < 4 {
                            multiSelections7.insert(i)
                        }
                        step7ContinueVisible = true
                    }
                }
            }
            Text("You can select multiple answers")
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(Color(white: 0.35))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
            if step7ContinueVisible {
                Spacer().frame(height: 16)
                v2Button("Continue") { handleStep7Continue() }
                    .disabled(multiSelections7.isEmpty)
                    .opacity(multiSelections7.isEmpty ? 0.28 : 1)
                    .transition(.opacity.animation(.easeIn(duration: 0.3)))
            }
        }
    }

    private func handleStep7Continue() {
        guard !isTransitioning, !multiSelections7.isEmpty else { return }

        // Priority order: option index 0 > 2 > 1 > 3
        let priorityOrder = [0, 2, 1, 3]
        let priorityPick = priorityOrder.first { multiSelections7.contains($0) } ?? multiSelections7.min() ?? 0
        quizSelections[2] = priorityPick

        let q = anchorTexts[7]
        let selectedLabels = multiSelections7.sorted().map { quizOptions[2][$0] }
        let answerText = selectedLabels.joined(separator: " + ")
        let reflection = quizReflections[2][priorityPick]

        showReflectionAndAdvance(q: q, a: answerText, reflection: reflection)
    }

    // MARK: Step 8 — multi-select, priority reflection

    private var step8MultiQuiz: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 14)
            VStack(spacing: 10) {
                ForEach(Array(quizOptions[3].enumerated()), id: \.offset) { i, option in
                    v2Pill(option, selected: multiSelections8.contains(i)) {
                        guard !isTransitioning else { return }
                        if multiSelections8.contains(i) {
                            multiSelections8.remove(i)
                        } else if multiSelections8.count < 4 {
                            multiSelections8.insert(i)
                        }
                        step8ContinueVisible = true
                    }
                }
            }
            Text("You can select multiple answers")
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(Color(white: 0.35))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
            if step8ContinueVisible {
                Spacer().frame(height: 16)
                v2Button("Continue") { handleStep8Continue() }
                    .disabled(multiSelections8.isEmpty)
                    .opacity(multiSelections8.isEmpty ? 0.28 : 1)
                    .transition(.opacity.animation(.easeIn(duration: 0.3)))
            }
        }
    }

    private func handleStep8Continue() {
        guard !isTransitioning, !multiSelections8.isEmpty else { return }

        // Priority order: 0 > 1 > 2 > 3 (natural ascending — lowest index wins)
        let priorityPick = multiSelections8.min() ?? 0
        quizSelections[3] = priorityPick

        let q = anchorTexts[8]
        let selectedLabels = multiSelections8.sorted().map { quizOptions[3][$0] }
        let answerText = selectedLabels.joined(separator: " + ")
        let reflection = quizReflections[3][priorityPick]

        showReflectionAndAdvance(q: q, a: answerText, reflection: reflection)
    }

    // MARK: Step 10 — right now, where are you (single + free text)

    private var step10WhereAreYou: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 14)
            if step10ShowTextField {
                // Pills hidden while keyboard is open — keeps button above keyboard
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .leading) {
                        if customAnswer.isEmpty {
                            Text("Tell me more...")
                                .font(.custom("HelveticaNeue", size: 16))
                                .foregroundColor(.white.opacity(0.20))
                        }
                        TextField("", text: $customAnswer)
                            .font(.custom("HelveticaNeue", size: 16))
                            .foregroundColor(.white)
                            .tint(.white)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit { submitStep10() }
                    }
                    .padding(.vertical, 10)
                    .overlay(
                        Rectangle().fill(Color.white.opacity(0.14)).frame(height: 1),
                        alignment: .bottom
                    )
                    Spacer().frame(height: 20)
                    v2Button("Done") { submitStep10() }
                }
                .transition(.opacity.animation(.easeIn(duration: 0.25)))
            } else {
                VStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { i in
                        v2Pill(quizOptions[5][i], selected: quizSelections[5] == i) {
                            guard !isTransitioning else { return }
                            quizSelections[5] = i
                            let q = anchorTexts[10]
                            let a = quizOptions[5][i]
                            let reflection = quizReflections[5][i]
                            isTransitioning = true
                            contentVisible = false
                            var updated = history
                            for j in 0..<updated.count { updated[j].age += 1 }
                            updated.append(V2MemoryEntry(question: q, answer: a, age: 0))
                            history = updated
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { typedText = "" }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                                isTransitioning = false
                                let chars = Array(reflection)
                                for (k, char) in chars.enumerated() {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(k) * 0.022) {
                                        typedText.append(char)
                                        if k == chars.count - 1 {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                                advance(q: reflection, a: "")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    // Pill 4 — free text option
                    v2Pill(quizOptions[5][4], selected: false) {
                        guard !isTransitioning else { return }
                        quizSelections[5] = 4
                        withAnimation(.easeIn(duration: 0.2)) { step10ShowTextField = true }
                    }
                }
            }
        }
    }

    private func submitStep10() {
        guard !isTransitioning else { return }
        let q = anchorTexts[10]
        let a = customAnswer.trimmingCharacters(in: .whitespaces).isEmpty ? "something else" : customAnswer.trimmingCharacters(in: .whitespaces)
        let reflection = quizReflections[5][4]
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        showReflectionAndAdvance(q: q, a: a, reflection: reflection)
    }

    // MARK: Step 11 — building brain

    private var step8: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 14)
            Rectangle()
                .fill(Color(white: 0.10))
                .frame(height: 1)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white)
                        .frame(height: 1)
                        .scaleEffect(x: buildProgress, y: 1, anchor: .leading)
                }
            if buildDone {
                Spacer().frame(height: 16)
                Text("Trained for the way you think.")
                    .font(.custom("Poppins-Regular", size: 15))
                    .foregroundColor(.white.opacity(0.32))
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: buildDone)
        .onAppear {
            buildProgress = 0
            buildDone = false
            withAnimation(.linear(duration: 2.2)) { buildProgress = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { buildDone = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) { advanceNoHistory() }
        }
    }

    // MARK: Step 13 — pattern reveal (full-screen)

    private var patternIsFraction: Bool { quizSelections[5] == 2 }

    private var patternNumber: Int {
        let s0 = quizSelections[0]
        let s5 = quizSelections[5]
        if s0 == 0 && multiSelections8.contains(0)                              { return 73 }
        if s0 == 0 && s5 == 1                                                    { return 71 }
        if s0 == 0 && multiSelections8.contains(1)                               { return 68 }
        if s0 == 1 && s5 == 1                                                    { return 67 }
        if s0 == 1 && multiSelections8.contains(0)                               { return 64 }
        if (quizSelections[4] == 2 || quizSelections[4] == 3) && s5 == 1        { return 64 }
        if s5 == 3                                                                { return 58 }
        if s0 == 2                                                                { return 61 }
        if s0 == 3                                                                { return 54 }
        return 67
    }

    private var patternSourceLine: String {
        "Drawn from people who answered exactly like you.\nThe percentage is drawn from your answer pattern."
    }

    private var patternRevealFallbackText: String {
        switch quizSelections[0] {
        case 0:
            return "Most people who overthink constantly already know what they should do. You carry decisions with you constantly. You've been sitting with this longer than you should. You already know the answer — you just can't trust it yet. That's not weakness. That's the most common reason people stay stuck."
        case 1:
            return "Most people who face this often share your exact pattern. You overthink more than most. You've been going back and forth longer than feels right. Part of what's keeping you stuck isn't the decision — it's the noise around it. That's not overthinking. That's caring about getting it right."
        case 2:
            return "Most people who face this occasionally feel it this heavily when they do. You don't overthink everything — just the ones that matter. And when they matter, they really matter. That's why the small decisions feel easy and the real ones feel impossible."
        case 3:
            return "Most people who rarely face this feel the weight of it this much when they do. You don't do this often — but when you do, it's real. The rarest decisions carry the most weight. That's not indecision. That's knowing what actually matters."
        default:
            return "Most people who face this often share your exact pattern. You overthink more than most. You've been going back and forth longer than feels right. Part of what's keeping you stuck isn't the decision — it's the noise around it. That's not overthinking. That's caring about getting it right."
        }
    }

    private var displayText: String {
        let raw = patternRevealLoaded && !patternRevealContent.isEmpty
            ? patternRevealContent
            : patternRevealFallbackText
        return raw
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func quizAnswerText(for selection: Int?, step: Int) -> String {
        guard let idx = selection else { return "unknown" }
        switch step {
        case 5:  return idx < quizOptions[0].count ? quizOptions[0][idx] : "unknown"
        case 9:  return idx < quizOptions[4].count ? quizOptions[4][idx] : "unknown"
        case 10:
            if idx < 4 { return idx < quizOptions[5].count ? quizOptions[5][idx] : "unknown" }
            return customAnswer.isEmpty ? "something else" : customAnswer
        default: return "unknown"
        }
    }

    private func selectedBlockerTexts() -> [String] {
        multiSelections8.sorted().map { idx in
            idx < quizOptions[3].count ? quizOptions[3][idx] : "unknown"
        }
    }

    private func triggerContentDisplayIfReady() {
        guard patternRevealPhase >= 3, !patternContentAnimating else { return }
        guard patternRevealLoaded || patternRevealFailed else { return }
        patternContentAnimating = true
        loadingPulse = false

        withAnimation(.easeIn(duration: 0.5)) { patternDescriptionPhase = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            guard patternRevealPhase < 4 else { return }
            withAnimation(.easeIn(duration: 0.4)) { patternRevealPhase = 4 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            guard patternRevealPhase < 5 else { return }
            withAnimation(.easeIn(duration: 0.4)) { patternRevealPhase = 5 }
        }
    }

    private var patternRevealView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                Group {
                    if patternIsFraction {
                        Text("You're ")
                            + Text("1 of 3").foregroundColor(Color(red: 0.18, green: 0.78, blue: 0.72))
                            + Text(" thinking types.")
                    } else {
                        Text("You think like ")
                            + Text("\(patternNumber)").foregroundColor(Color(red: 0.18, green: 0.78, blue: 0.72))
                            + Text(" out of 100 people.")
                    }
                }
                .font(.custom("HelveticaNeue-UltraLight", size: 28))
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(patternRevealPhase >= 1 ? 1 : 0)
                .animation(.easeIn(duration: 0.5), value: patternRevealPhase >= 1)
                .padding(.horizontal, 36)

                if patternRevealPhase >= 3 {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Here's what that means for you:")
                            .font(.custom("HelveticaNeue-Light", size: 16))
                            .foregroundColor(.white.opacity(0.40))
                            .opacity(patternDescriptionPhase >= 1 ? 1 : 0)
                            .animation(.easeIn(duration: 0.5), value: patternDescriptionPhase)

                        if !patternRevealLoaded && !patternRevealFailed {
                            HStack(spacing: 8) {
                                ForEach(0..<3, id: \.self) { i in
                                    Circle()
                                        .fill(Color.white.opacity(loadingPulse ? 0.5 : 0.12))
                                        .frame(width: 5, height: 5)
                                        .animation(
                                            .easeInOut(duration: 0.55)
                                                .repeatForever(autoreverses: true)
                                                .delay(Double(i) * 0.18),
                                            value: loadingPulse
                                        )
                                }
                            }
                            .onAppear { loadingPulse = true }
                        } else {
                            Text(displayText)
                                .font(.custom("HelveticaNeue-Light", size: 18))
                                .foregroundColor(.white.opacity(0.75))
                                .multilineTextAlignment(.leading)
                                .lineSpacing(5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .opacity(patternDescriptionPhase >= 1 ? 1 : 0)
                                .animation(.easeIn(duration: 0.5), value: patternDescriptionPhase)
                        }
                    }
                    .padding(.horizontal, 36)
                    .padding(.top, 32)
                }

                Spacer()

                Button {
                    withAnimation(.easeOut(duration: 0.3)) { patternRevealDismissOpacity = 0 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { advanceNoHistory() }
                } label: {
                    Text("Continue")
                        .font(.custom("HelveticaNeue", size: 17))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 32)
                .padding(.bottom, 12)
                .opacity(patternRevealPhase >= 5 ? 1 : 0)
                .animation(.easeIn(duration: 0.4), value: patternRevealPhase >= 5)

                Text(patternSourceLine)
                    .font(.custom("HelveticaNeue", size: 13))
                    .foregroundColor(.white.opacity(0.25))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 36)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                    .opacity(patternRevealPhase >= 2 ? 1 : 0)
                    .animation(.easeIn(duration: 0.4), value: patternRevealPhase >= 2)
            }

            VStack {
                Text("Tap to skip animation")
                    .font(.custom("HelveticaNeue", size: 11))
                    .foregroundColor(.white.opacity(0.25))
                    .padding(.top, 70)
                    .opacity(patternRevealPhase < 5 ? 1 : 0)
                    .animation(.easeOut(duration: 0.25), value: patternRevealPhase >= 5)
                Spacer()
            }
        }
        .opacity(patternRevealDismissOpacity)
        .contentShape(Rectangle())
        .onTapGesture {
            guard patternRevealPhase < 5 else { return }
            if patternRevealLoaded || patternRevealFailed {
                patternContentAnimating = true
                loadingPulse = false
                patternDescriptionPhase = 1
                withAnimation(.easeIn(duration: 0.3)) { patternRevealPhase = 5 }
            } else {
                withAnimation(.easeIn(duration: 0.3)) { patternRevealPhase = 3 }
            }
        }
        .onAppear {
            patternRevealPhase = 0
            patternRevealDismissOpacity = 1
            patternRevealContent = ""
            patternRevealLoaded = false
            patternRevealFailed = false
            patternDescriptionPhase = 0
            patternContentAnimating = false
            loadingPulse = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                guard patternRevealPhase < 1 else { return }
                withAnimation(.easeIn(duration: 0.5)) { patternRevealPhase = 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                guard patternRevealPhase < 2 else { return }
                withAnimation(.easeIn(duration: 0.4)) { patternRevealPhase = 2 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                guard patternRevealPhase < 3 else { return }
                patternRevealPhase = 3
                triggerContentDisplayIfReady()
            }

            Task {
                do {
                    let frequency = quizAnswerText(for: quizSelections[0], step: 5)
                    let blockers = selectedBlockerTexts()
                    let duration = quizAnswerText(for: quizSelections[4], step: 9)
                    let currentState = quizAnswerText(for: quizSelections[5], step: 10)

                    let content = try await APIClient.shared.generatePatternReveal(
                        frequency: frequency,
                        blockers: blockers,
                        duration: duration,
                        currentState: currentState
                    )
                    await MainActor.run {
                        patternRevealContent = content
                        patternRevealLoaded = true
                        triggerContentDisplayIfReady()
                    }
                } catch {
                    await MainActor.run {
                        patternRevealFailed = true
                        triggerContentDisplayIfReady()
                    }
                }
            }
        }
    }

    // MARK: Step 16 — how we help (full-screen)

    private var howWeHelpView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                VStack(alignment: .leading, spacing: 0) {
                    Text("How we help.")
                        .font(.custom("HelveticaNeue", size: 32))
                        .foregroundColor(.white)
                        .padding(.bottom, 32)
                        .opacity(howWeHelpPhase >= 1 ? 1 : 0)
                    // TODO: Replace "we" in block 02 title with final app name once decided
                    howBlock("01", "Bring it something real.", "A decision. A feeling.\nSomething stuck in your head.")
                        .opacity(howWeHelpPhase >= 1 ? 1 : 0)
                    Rectangle().fill(Color(white: 0.07)).frame(height: 1)
                        .opacity(howWeHelpPhase >= 2 ? 1 : 0)
                    howBlock("02", "We run it forward.", "Outcomes. Tradeoffs. Consequences.\nQuietly. In seconds.")
                        .opacity(howWeHelpPhase >= 2 ? 1 : 0)
                    Rectangle().fill(Color(white: 0.07)).frame(height: 1)
                        .opacity(howWeHelpPhase >= 3 ? 1 : 0)
                    howBlock("03", "You see farther.", "What keeps showing up.\nWhat emotion was hiding.")
                        .opacity(howWeHelpPhase >= 3 ? 1 : 0)
                }
                .padding(.horizontal, 36)
                Spacer()
                v2Button("Continue") { advanceNoHistory() }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 52)
                    .opacity(howWeHelpPhase >= 4 ? 1 : 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack {
                Text("Tap to skip animation")
                    .font(.custom("HelveticaNeue", size: 11))
                    .foregroundColor(.white.opacity(0.25))
                    .padding(.top, 70)
                    .opacity(howWeHelpPhase < 4 ? 1 : 0)
                    .animation(.easeOut(duration: 0.25), value: howWeHelpPhase >= 4)
                Spacer()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard howWeHelpPhase < 4 else { return }
            withAnimation(.easeIn(duration: 0.3)) { howWeHelpPhase = 4 }
        }
        .onAppear {
            howWeHelpPhase = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                guard howWeHelpPhase < 1 else { return }
                withAnimation(.easeIn(duration: 0.5)) { howWeHelpPhase = 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                guard howWeHelpPhase < 2 else { return }
                withAnimation(.easeIn(duration: 0.5)) { howWeHelpPhase = 2 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                guard howWeHelpPhase < 3 else { return }
                withAnimation(.easeIn(duration: 0.5)) { howWeHelpPhase = 3 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
                guard howWeHelpPhase < 4 else { return }
                withAnimation(.easeIn(duration: 0.5)) { howWeHelpPhase = 4 }
            }
        }
    }

    private func howBlock(_ n: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 20) {
            Text(n)
                .font(.custom("HelveticaNeue", size: 48))
                .foregroundColor(Color(white: 0.40))
                .frame(width: 64, alignment: .leading)
                .lineLimit(1)
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.custom("HelveticaNeue", size: 22))
                    .foregroundColor(.white)
                    .padding(.top, 6)
                Text(body)
                    .font(.custom("HelveticaNeue", size: 14))
                    .foregroundColor(.white.opacity(0.36))
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 20)
    }

    // MARK: Step 17 — interactive demo (user types, live verdict card)

    private var demoInputReady: Bool {
        demoInput.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
    }

    private var demoThinkView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // ── Intro beat — fades in, holds, fades out (like the good/bad
            //    news transition) before the input appears ─────────────────
            if demoShowIntro {
                Text("Okay — now it's your turn to experience it.")
                    .font(.custom("Poppins-Regular", size: 19))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(demoIntroPhase >= 1 ? 1 : 0)
            }

            // ── Input (centered) — shown before Think ────────────────────
            if demoInputVisible {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()

                    Text("Try it now.")
                        .font(.custom("HelveticaNeue", size: 30))
                        .foregroundColor(.white)
                        .padding(.bottom, 22)

                    // Growing text box — expands as the user types
                    ZStack(alignment: .topLeading) {
                        if demoInput.isEmpty {
                            Text("e.g. should I quit my job, move cities, end a relationship...")
                                .font(.custom("HelveticaNeue", size: 21))
                                .foregroundColor(.white.opacity(0.20))
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)   // let taps reach the field
                        }
                        TextField("", text: $demoInput, axis: .vertical)
                            .font(.custom("HelveticaNeue", size: 21))
                            .foregroundColor(.white)
                            .tint(.white)
                            .lineLimit(1...6)
                            .autocorrectionDisabled()
                            .focused($demoInputFocused)
                            .padding(.vertical, 12)
                            .onChange(of: demoInput) { newVal in
                                if newVal.count > 280 { demoInput = String(newVal.prefix(280)) }
                            }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { demoInputFocused = true }
                    .overlay(
                        Rectangle().fill(Color.white.opacity(0.16)).frame(height: 1),
                        alignment: .bottom
                    )

                    if demoInput.count >= 250 {
                        Text("\(demoInput.count)/280")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.30))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.top, 6)
                    }

                    Spacer().frame(height: 28)

                    v2Button("Think") { runDemoThink() }
                        .opacity(demoInputReady ? 1 : 0.28)
                        .disabled(!demoInputReady || demoThinking)

                    Button { advanceNoHistory() } label: {
                        Text("skip →")
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundColor(.white.opacity(0.33))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)

                    Spacer()
                }
                .padding(.horizontal, 28)
                .transition(.opacity)
            }

            // ── Result card + Continue — shown after thinking ────────────
            if (demoResult != nil || demoFallback) && !demoPostActive && !demoTailoredActive && !demoReviewActive {
                VStack(spacing: 0) {
                    Spacer(minLength: 16)

                    Group {
                        if let result = demoResult {
                            // Same card as the main app — flippable front (verdict)
                            // / back deep dive, rendered identically to the story view
                            demoFlipCard(result: result)
                        } else {
                            demoFallbackCard
                        }
                    }
                    .aspectRatio(0.68, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 440)
                    .padding(.horizontal, 28)
                    .offset(y: demoCardOffset)

                    Spacer(minLength: 16)

                    Button {
                        if demoResult != nil { startDemoPostSequence() } else { advanceNoHistory() }
                    } label: {
                        Text("Continue →")
                            .font(.custom("HelveticaNeue", size: 17))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 28)
                    .padding(.bottom, 52)
                    .opacity(demoContinueVisible ? 1 : 0)
                    .disabled(!demoContinueVisible)
                    .animation(.easeIn(duration: 0.4), value: demoContinueVisible)
                }
                .transition(.opacity)
            }

            // ── Fade in/out message beats (before and after chat) ────────
            if demoPostActive {
                ZStack {
                    Text(demoPostBeatText)
                        .font(.custom("Poppins-Regular", size: 19))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 40)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if demoBeatTappable {
                        VStack {
                            Spacer()
                            Text("tap to continue")
                                .font(.custom("Poppins-Regular", size: 13))
                                .foregroundColor(.white.opacity(0.35))
                                .padding(.bottom, 120)
                        }
                    }
                }
                .opacity(demoPostPhase >= 1 ? 1 : 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { handleDemoBeatTap() }
            }

            // ── Structured "tailored to you" reveal (after final beat) ───
            if demoTailoredActive {
                demoTailoredView
                    .transition(.opacity)
            }

            // ── Review screen — one question, then the Apple review prompt ─
            if demoReviewActive {
                demoReviewView
                    .transition(.opacity)
            }

            // ── Loading — the app's real simulating state ────────────────
            if demoThinking {
                SimulatingView()
                    .transition(.opacity)
            }

            // ── Follow-up question — same view the main app uses ─────────
            if demoShowFollowUp {
                QuestionCardView(
                    question: demoFollowUpQ,
                    onSubmit: { answer in submitDemoFollowUp(answer) },
                    onSkip: { submitDemoFollowUp("") }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            // Shared resets
            demoThinking = false
            demoFallback = false
            demoResolved = false
            demoShowFollowUp = false
            demoFollowUpQ = ""
            demoPostActive = false
            demoPostPhase = 0
            demoPostMessage = 1
            demoBeatTappable = false
            demoTailoredActive = false
            demoTailoredPhase = 0
            demoReviewActive = false
            demoReviewPhase = 0
            demoReviewAdvanced = false
            demoThinkCompleted = false
            demoShowChat = false
            demoLayoutIndex = 1                 // always Layout B — never changes
            demoCardAngle = 0
            demoTiltX = 0
            demoThinkID = UUID()

            #if DEBUG
            // Debug entry points — jump straight to a sample card / chat / review
            if demoDebugCard || demoDebugChat || demoDebugReview {
                applyDemoDebug(openChat: demoDebugChat, openReview: demoDebugReview)
                return
            }
            #endif

            // Normal flow
            demoInput = ""
            demoInputVisible = false
            demoShowIntro = true
            demoIntroPhase = 0
            demoResult = nil
            demoContinueVisible = false
            demoCardOffset = UIScreen.main.bounds.height + 200
            // Intro message fades in, holds, fades out — then the input fades in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.7)) { demoIntroPhase = 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                withAnimation(.easeInOut(duration: 0.7)) { demoIntroPhase = 0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.1) {
                demoShowIntro = false
                withAnimation(.easeIn(duration: 0.5)) { demoInputVisible = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    demoInputFocused = true
                }
            }
        }
        #if DEBUG
        // Handle debug jumps even when already on step 17 (onAppear won't re-fire)
        .onChange(of: demoDebugCard) { on in if on { applyDemoDebug() } }
        .onChange(of: demoDebugChat) { on in if on { applyDemoDebug(openChat: true) } }
        .onChange(of: demoDebugReview) { on in if on { applyDemoDebug(openReview: true) } }
        #endif
    }

    #if DEBUG
    private func applyDemoDebug(openChat: Bool = false, openReview: Bool = false) {
        demoDebugCard = false
        demoDebugChat = false
        demoDebugReview = false
        demoThinking = false
        demoFallback = false
        demoResolved = false
        demoShowFollowUp = false
        demoFollowUpQ = ""
        demoPostActive = false
        demoPostPhase = 0
        demoPostMessage = 1
        demoBeatTappable = false
        demoTailoredActive = false
        demoTailoredPhase = 0
        demoReviewActive = false
        demoReviewPhase = 0
        demoReviewAdvanced = false
        demoShowChat = false
        demoShowIntro = false
        demoIntroPhase = 0
        demoInputVisible = false
        demoCardAngle = 0
        demoTiltX = 0
        demoLayoutIndex = 1
        demoThinkID = UUID()
        demoInput = "should I take the job offer in a new city?"
        demoResult = demoSampleResult()
        demoThinkCompleted = true          // debug jumps simulate a completed think
        demoContinueVisible = true
        demoCardOffset = 0
        if openReview {
            withAnimation(.easeIn(duration: 0.4)) { demoReviewActive = true }
        } else if openChat {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.4)) { demoShowChat = true }
            }
        }
    }
    #endif

    // Sample fully-populated result — DEBUG only, for the card/chat jump buttons.
    #if DEBUG
    private func demoSampleResult() -> DecisionResult {
        let json = """
        {
          "verdict": "Take the offer — but negotiate a start date that lets you land on your feet.",
          "confidence": 74,
          "simulationCount": 1000,
          "mode": "DECISION",
          "reasoning": "A better role in a new city is rarely just about the job — it's about who you become in it. The upside here is real and the downside is mostly recoverable. Protect the transition and the move pays off.",
          "whyPoints": ["the role itself is a clear step up", "a fresh city resets stale patterns", "the downside is recoverable, the upside compounds"],
          "tradeoffs": ["leaving a known support system behind", "short-term disruption for long-term growth", "proximity to family vs. proximity to opportunity"],
          "majorityOutcomes": [
            {"percentage": 46, "title": "Pays off", "explanation": "The role and the change accelerate you within a year"},
            {"percentage": 21, "title": "Slow settle", "explanation": "Great job, but the city takes time to feel like home"},
            {"percentage": 9, "title": "Homesick", "explanation": "The distance weighs more than expected"}
          ],
          "minorityOutcomes": [
            {"percentage": 14, "title": "Breakout", "explanation": "The move opens doors you couldn't see from here"},
            {"percentage": 6, "title": "Regret", "explanation": "What you left behind mattered more than the title"},
            {"percentage": 4, "title": "Boomerang", "explanation": "You return later, but wiser for having gone"}
          ],
          "patternNote": "",
          "whatYoureNotSaying": "You already want to go. You're really asking whether it's okay to choose yourself here.",
          "whatUsuallyHelps": "Name the one thing that would make leaving feel safe, then build that into the offer.",
          "needsAmbientQuestion": false,
          "ambientQuestion": "",
          "archetype": {
            "name": "The Builder",
            "description": "you move when the evidence is there.",
            "percentage": 19
          }
        }
        """.data(using: .utf8)!
        if let r = try? JSONDecoder().decode(DecisionResult.self, from: json) { return r }
        return .mock
    }
    #endif

    private var demoPostBeatText: String {
        switch demoPostMessage {
        case 1:  return "It's not over yet."
        case 2:  return "The verdict is only step one.\nEvery decision has nuance.\nKeep exploring until it feels right."
        default: return "It doesn't stop there."
        }
    }

    // After chat closes: "It doesn't stop there." beat → structured reveal screen.
    private func startDemoFinalBeat() {
        demoShowChat = false
        demoBeatTappable = false
        demoTailoredActive = false
        demoTailoredPhase = 0
        demoPostMessage = 3
        demoPostPhase = 0
        withAnimation(.easeInOut(duration: 0.4)) { demoPostActive = true }
        // "It doesn't stop there." — fade in, hold, fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.7)) { demoPostPhase = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.7)) { demoPostPhase = 0 }
        }
        // Switch to the structured left-aligned reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.9) {
            demoPostActive = false
            withAnimation(.easeIn(duration: 0.5)) { demoTailoredActive = true }
            startDemoTailoredReveal()
        }
    }

    // Reveal the "every decision teaches Bracket …" screen line by line.
    private func startDemoTailoredReveal() {
        let steps = 6   // heading + 4 timeline dots + closing line
        for phase in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(phase) * 0.6) {
                withAnimation(.easeInOut(duration: 0.5)) { demoTailoredPhase = phase }
            }
        }
        // Enable tap-to-continue after the last line lands
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(steps) * 0.6 + 0.6) {
            demoBeatTappable = true
        }
    }

    // Left-aligned: heading, a vertical line connecting dots, closing line.
    private var demoTailoredView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                Text("Every decision teaches Bracket")
                    .font(.custom("HelveticaNeue", size: 24))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(demoTailoredPhase >= 1 ? 1 : 0)
                    .padding(.bottom, 26)

                // Vertical timeline — dots connected by a single vertical line
                VStack(alignment: .leading, spacing: 0) {
                    demoTailoredRow("How you think",                 visible: demoTailoredPhase >= 2)
                    demoTailoredRow("What you value",                visible: demoTailoredPhase >= 3)
                    demoTailoredRow("The choices you make",          visible: demoTailoredPhase >= 4)
                    demoTailoredRow("The patterns of your thoughts", visible: demoTailoredPhase >= 5, isLast: true)
                }

                Text("So every verdict becomes more tailored to you.")
                    .font(.custom("Poppins-Regular", size: 17))
                    .foregroundColor(.white)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(demoTailoredPhase >= 6 ? 1 : 0)
                    .padding(.top, 26)

                Spacer()

                Button { goToDemoReview() } label: {
                    Text("Continue")
                        .font(.custom("HelveticaNeue", size: 17))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 40)
                .opacity(demoBeatTappable ? 1 : 0)
                .disabled(!demoBeatTappable)
                .animation(.easeIn(duration: 0.4), value: demoBeatTappable)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 36)
        }
    }

    private func goToDemoReview() {
        demoBeatTappable = false
        // Cross-fade in one step so the card never peeks through the gap
        withAnimation(.easeInOut(duration: 0.5)) {
            demoTailoredActive = false
            demoReviewActive = true
        }
    }

    // One timeline row: a dot, a vertical connector that grows into the next dot.
    private func demoTailoredRow(_ text: String, visible: Bool, isLast: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 9, height: 9)
                    .padding(.top, 5)
                    .opacity(visible ? 1 : 0)
                    .scaleEffect(visible ? 1 : 0.4)
                if !isLast {
                    Rectangle()
                        .fill(Color(white: 0.28))
                        .frame(width: 1.5, height: 34)
                        // Line grows downward from this dot toward the next one
                        .scaleEffect(x: 1, y: visible ? 1 : 0, anchor: .top)
                }
            }
            Text(text)
                .font(.custom("HelveticaNeue", size: 18))
                .foregroundColor(.white.opacity(0.85))
                .padding(.bottom, isLast ? 0 : 26)
                .opacity(visible ? 1 : 0)
            Spacer()
        }
    }

    // Review screen — one question, then the Apple review prompt pops.
    private var demoReviewView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 90)
                Text("One question.")
                    .font(.custom("HelveticaNeue", size: 30))
                    .foregroundColor(.white)
                    .opacity(demoReviewPhase >= 1 ? 1 : 0)
                Spacer().frame(height: 14)
                Text("How did that experience feel?")
                    .font(.custom("Poppins-Regular", size: 17))
                    .foregroundColor(.white.opacity(0.5))
                    .opacity(demoReviewPhase >= 2 ? 1 : 0)
                Spacer()
                Button { advanceFromReview() } label: {
                    Text("Continue")
                        .font(.custom("HelveticaNeue", size: 17))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 40)
                .opacity(demoReviewPhase >= 3 ? 1 : 0)
                .disabled(demoReviewPhase < 3)
                .animation(.easeIn(duration: 0.4), value: demoReviewPhase)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 36)
        }
        .onAppear {
            demoReviewPhase = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.6)) { demoReviewPhase = 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                withAnimation(.easeInOut(duration: 0.6)) { demoReviewPhase = 2 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                triggerReviewPrompt()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                withAnimation(.easeInOut(duration: 0.6)) { demoReviewPhase = 3 }
            }
        }
    }

    // Single-shot advance from the review screen (guards Continue vs auto-advance).
    private func advanceFromReview() {
        guard !demoReviewAdvanced else { return }
        demoReviewAdvanced = true
        advanceNoHistory()
    }

    private func triggerReviewPrompt() {
        // Only ask people who actually experienced a completed think — never skippers.
        guard demoThinkCompleted else { return }
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    // After the card's Continue: beat 1 auto-fades, beat 2 waits for a tap → chat.
    private func startDemoPostSequence() {
        demoBeatTappable = false
        demoPostMessage = 1
        demoPostPhase = 0
        withAnimation(.easeInOut(duration: 0.5)) { demoPostActive = true }
        // Beat 1 (short) — auto in → out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.7)) { demoPostPhase = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.9) {
            withAnimation(.easeInOut(duration: 0.7)) { demoPostPhase = 0 }
        }
        // Beat 2 — fade in, then wait for a tap
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
            demoPostMessage = 2
            withAnimation(.easeInOut(duration: 0.7)) { demoPostPhase = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { demoBeatTappable = true }
        }
    }

    // Tap handler for the tap-to-continue beats (message 2 → chat, 3 → advance).
    private func handleDemoBeatTap() {
        guard demoBeatTappable else { return }
        demoBeatTappable = false
        let msg = demoPostMessage
        withAnimation(.easeInOut(duration: 0.6)) { demoPostPhase = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            if msg == 2 {
                withAnimation(.easeInOut(duration: 0.4)) { demoShowChat = true }
            } else {
                advanceNoHistory()
            }
        }
    }

    // Fallback card — shown only after several real failures.
    private var demoFallbackCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10).fill(Color.black)
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5))
            Text("something went wrong — but your decision is worth thinking through properly. keep going.")
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 26)
        }
        .shadow(color: Color.white.opacity(0.06), radius: 24, x: 0, y: 0)
    }

    private func runDemoThink() {
        let q = demoInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 10, !demoThinking, demoResult == nil, !demoFallback, !demoShowFollowUp else { return }
        demoInputFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        demoResolved = false
        withAnimation(.easeOut(duration: 0.3)) { demoInputVisible = false }
        withAnimation(.easeIn(duration: 0.4)) { demoThinking = true }
        // Full app flow: firstPass (triage — may ask a follow-up) → secondPass.
        // Uses the exact same client + Haiku model the app uses. Retries a few
        // times before ever falling back so a transient failure never surfaces.
        Task {
            var fp: FirstPassResponse? = nil
            for attempt in 0..<4 {
                if let r = try? await APIClient.shared.firstPass(question: q, useHaiku: true) {
                    fp = r
                    break
                }
                if attempt < 3 { try? await Task.sleep(nanoseconds: 800_000_000) }
            }
            guard let fp = fp else {
                await MainActor.run { resolveDemoThink(result: nil) }
                return
            }
            if fp.needsQuestion && !fp.question.trimmingCharacters(in: .whitespaces).isEmpty {
                await MainActor.run {
                    demoFollowUpQ = fp.question
                    withAnimation(.easeInOut(duration: 0.4)) { demoThinking = false }
                    withAnimation(.easeIn(duration: 0.35)) { demoShowFollowUp = true }
                }
            } else {
                await runDemoSecondPass(question: q, answer: "")
            }
        }
    }

    private func submitDemoFollowUp(_ answer: String) {
        let q = demoInput.trimmingCharacters(in: .whitespacesAndNewlines)
        Task { await runDemoSecondPass(question: q, answer: answer) }
    }

    private func runDemoSecondPass(question q: String, answer: String) async {
        await MainActor.run {
            withAnimation(.easeOut(duration: 0.3)) { demoShowFollowUp = false }
            withAnimation(.easeIn(duration: 0.4)) { demoThinking = true }
        }
        var result: DecisionResult? = nil
        for attempt in 0..<4 {
            if let r = try? await APIClient.shared.secondPass(question: q, followUpAnswer: answer, useHaiku: true) {
                result = r
                break
            }
            if attempt < 3 { try? await Task.sleep(nanoseconds: 800_000_000) }
        }
        await MainActor.run { resolveDemoThink(result: result) }
    }

    private func resolveDemoThink(result: DecisionResult?) {
        guard !demoResolved else { return }
        demoResolved = true
        if let result = result {
            demoResult = result
            demoLayoutIndex = 1
            demoThinkCompleted = true      // real think finished → review is earned
        } else {
            demoFallback = true
        }
        withAnimation(.easeInOut(duration: 0.4)) { demoThinking = false }
        // Card slides up — same spring as the main-app result card
        withAnimation(.spring(response: 1.0, dampingFraction: 0.85)) { demoCardOffset = 0 }
        // Continue fades in 1.5s after the card content loads
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            demoContinueVisible = true
        }
    }

    // Flippable card — mirrors DecisionCardView.floatGlow: front verdict card,
    // back deep dive (Why / Trade offs), drag-to-rotate + tap-to-flip.
    private var demoFrontVisible: Bool { cos(demoCardAngle * .pi / 180) >= 0 }

    private func demoFlipCard(result: DecisionResult) -> some View {
        ZStack {
            CardBackView(
                result: result,
                originalQuestion: demoInput,
                viewModel: viewModel,
                thinkID: demoThinkID,
                layoutIndex: demoLayoutIndex,
                existingChatMessages: [],
                onChatMessagesUpdated: { _ in },
                onNewThink: nil,
                onScrollingChanged: { demoBackScrolling = $0 },
                compact: true
            )
            .overlay(RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5))
            .rotation3DEffect(.degrees(demoCardAngle + 180), axis: (0, 1, 0), perspective: 1.1)
            .opacity(demoFrontVisible ? 0 : 1)

            DecisionCard(result: result, layoutIndex: demoLayoutIndex)
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5))
                .rotation3DEffect(.degrees(demoCardAngle), axis: (0, 1, 0), perspective: 1.1)
                .opacity(demoFrontVisible ? 1 : 0)
        }
        .rotation3DEffect(.degrees(demoTiltX), axis: (1, 0, 0), perspective: 0.6)
        .gesture(demoCardGesture)
        .shadow(color: Color.white.opacity(0.06), radius: 24, x: 0, y: 0)
    }

    private var demoCardGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                if !demoDragStarted {
                    demoDragStarted = true
                    demoDragBase = demoCardAngle
                }
                demoCardAngle = demoDragBase + Double(v.translation.width) * 0.55
                withAnimation(.interactiveSpring()) {
                    demoTiltX = max(-18, min(18, Double(-v.translation.height / 5)))
                }
            }
            .onEnded { v in
                let wasDrag = abs(v.translation.width) > 8
                demoDragStarted = false
                if wasDrag {
                    let velocity = Double(v.predictedEndTranslation.width - v.translation.width)
                    let snapped  = (demoCardAngle / 180).rounded() * 180
                    let raw      = abs(velocity) > 300
                        ? (velocity > 0 ? snapped + 180 : snapped - 180)
                        : snapped
                    let target = demoDragBase + max(-180.0, min(180.0, raw - demoDragBase))
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.68)) {
                        demoCardAngle = target
                        demoTiltX = 0
                    }
                } else {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.68)) { demoTiltX = 0 }
                    withAnimation(.easeInOut(duration: 0.44)) { demoCardAngle += 180 }
                }
            }
    }

    // MARK: Step 21 — nudge / notifications

    private var nudgeView: some View {
        let teal = Color(red: 0.18, green: 0.78, blue: 0.72)
        return ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer().frame(height: 64)
                Text("Allow the brain to nudge you.\nYou can always turn this off later.")
                    .font(.custom("HelveticaNeue-Bold", size: 24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 28)
                    .opacity(nudgePhase >= 1 ? 1 : 0)

                Spacer()

                VStack(spacing: 0) {
                    Image("notification_prompt")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)

                    HStack {
                        Spacer()
                        Image(systemName: "arrow.up")
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(teal)
                        Spacer().frame(width: 80)
                    }
                    .padding(.top, 12)
                }
                .padding(.horizontal, 28)
                .opacity(nudgePhase >= 2 ? 1 : 0)

                Spacer()

                v2Button("Continue") {
                    v2RequestNotifications {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            if viewModel.hasActiveEntitlement {
                                advanceNoHistory()
                            } else {
                                showDownsell = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
                .opacity(nudgePhase >= 3 ? 1 : 0)
            }
        }
        .onAppear {
            nudgePhase = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.6)) { nudgePhase = 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation(.easeInOut(duration: 0.6)) { nudgePhase = 2 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeInOut(duration: 0.6)) { nudgePhase = 3 }
            }
        }
    }

    // MARK: Step 21 — you're ready (cinematic)

    private var youreReadyView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                Text("You're ready.")
                    .font(.custom("HelveticaNeue", size: 32))
                    .foregroundColor(.white)
                    .opacity(youreReadyPhase >= 1 ? 1 : 0)
                Spacer().frame(height: 14)
                Text("Bring it something real.")
                    .font(.custom("Poppins-Regular", size: 17))
                    .foregroundColor(.white.opacity(0.38))
                    .opacity(youreReadyPhase >= 2 ? 1 : 0)
                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .onAppear {
            youreReadyPhase = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 1.2)) { youreReadyPhase = 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeInOut(duration: 1.0)) { youreReadyPhase = 2 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                withAnimation(.easeInOut(duration: 1.0)) { youreReadyPhase = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                    PostHogSDK.shared.capture("onboarding_completed")
                    onComplete()
                }
            }
        }
    }

    // MARK: Step 18 — features/value

    private var featuresView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 28) {
                    (Text("Those ")
                        .font(.custom("HelveticaNeue", size: 28))
                        .foregroundColor(.white)
                    + Text(personYearsNumber)
                        .font(.custom("HelveticaNeue-Bold", size: 28))
                        .foregroundColor(.white)
                    + Text(" years are still\nyours to take back.")
                        .font(.custom("HelveticaNeue", size: 28))
                        .foregroundColor(.white))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .opacity(featuresPhase >= 1 ? 1 : 0)

                    Text("But only if you stop\nletting hesitation decide.")
                        .font(.custom("HelveticaNeue", size: 28))
                        .foregroundColor(Color(white: 0.38))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .opacity(featuresPhase >= 2 ? 1 : 0)

                    Text("[ Bracket ] can help you\nget back those years.")
                        .font(.custom("HelveticaNeue", size: 15))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .opacity(featuresPhase >= 3 ? 1 : 0)
                }
                .padding(.horizontal, 36)
                Spacer()
                Button { advanceNoHistory() } label: {
                    Text("See your options")
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
                .opacity(featuresPhase >= 4 ? 1 : 0)
            }
        }
        .onAppear {
            featuresPhase = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 0.6)) { featuresPhase = 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                withAnimation(.easeIn(duration: 0.6)) { featuresPhase = 2 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
                withAnimation(.easeIn(duration: 0.6)) { featuresPhase = 3 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeIn(duration: 0.6)) { featuresPhase = 4 }
            }
        }
    }

    // MARK: Step 19 — paywall

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private var paywallView: some View {
        return ZStack {
            // Background image — kept exactly as is
            Image("onboarding_paywall_bg")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .offset(y: -60)
                .clipped()
                .ignoresSafeArea()

            Color.black.opacity(0.35).ignoresSafeArea()

            // Single adaptive content layer
            VStack(spacing: 0) {
                // TOP content
                VStack(alignment: .leading, spacing: 0) {
                    Text("Your next decision\nchanges everything.")
                        .font(.custom("HelveticaNeue-Bold", size: 26))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                        .padding(.top, 16)

                    Text("Spend less time stuck between\n\"what if\" and \"what now.\"")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(Color(white: 0.45))
                        .lineSpacing(4)
                        .padding(.top, 10)

                    VStack(alignment: .leading, spacing: 0) {
                        pwTimelineRow("checkmark", true,  "The thought",
                                      "Bring the thing you can't stop thinking about.", false)
                        pwTimelineRow("lightbulb.fill", false, "The verdict",
                                      "Thousands of simulations. One clear answer.", false)
                        pwTimelineRow("star.fill", false, "The outcome",
                                      "You start moving with clarity.", true)
                    }
                    .padding(.top, 16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 16).frame(maxHeight: isPad ? (UIScreen.main.bounds.width > 900 ? 480 : 320) : .infinity)

                // BOTTOM content
                VStack(alignment: .leading, spacing: 0) {
                    if selectedPlan == 0 {
                        VStack(spacing: 4) {
                            Text("7 Days for $0.00")
                                .font(.custom("HelveticaNeue-Bold", size: 17))
                                .foregroundColor(.white)
                            Text("Then \(paywallProPrice)/year. Cancel anytime.")
                                .font(.custom("Poppins-Regular", size: 13))
                                .foregroundColor(Color(white: 0.42))
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 4) {
                            Text("300 Thinks")
                                .font(.custom("HelveticaNeue-Bold", size: 17))
                                .foregroundColor(.white)
                            Text("\(paywallCorePrice) for 6 months.")
                                .font(.custom("Poppins-Regular", size: 13))
                                .foregroundColor(Color(white: 0.42))
                        }
                        .frame(maxWidth: .infinity)
                    }

                    VStack(spacing: 8) {
                        pwPlanCard(0, "PRO — Unlimited", "\(paywallProPrice)/year", "That's \(paywallProMonthly)/mo",
                                   ["unlimited thinks", "deeper simulations", "pattern memory"],
                                   "", true)
                        pwPlanCard(1, "CORE", "\(paywallCorePrice)/6mo", "That's \(paywallCoreMonthly)/mo",
                                   ["300 thinks", "full simulation access", "pattern tracking"],
                                   "")
                    }
                    .padding(.top, 12)

                    Button {
                        Task {
                            let productId: String = selectedPlan == 0 ? "com.brainla.bomb.pro.annual.v2" : "com.brainla.bomb.core.sixmonths.v2"
                            let selectedTier: AppTier = selectedPlan == 0 ? .pro : .core
                            print("DEBUG onboarding paywall buy: selectedPlan=\(selectedPlan), selectedTier=\(selectedTier)")
                            if let package = viewModel.currentOffering?.availablePackages.first(where: {
                                $0.storeProduct.productIdentifier == productId
                            }) {
                                let success = await viewModel.purchase(package: package)
                                if success {
                                    await MainActor.run {
                                        print("DEBUG onboarding confirmation tier = \(selectedTier)")
                                        onboardingConfirmationTier = selectedTier
                                        showOnboardingConfirmation = true
                                    }
                                }
                            } else {
                                await MainActor.run {
                                    purchaseErrorMessage = "Unable to load subscription. Please try again."
                                    showPurchaseError = true
                                }
                            }
                        }
                    } label: {
                        Text(selectedPlan == 0 ? "Start my 7-day free trial" : "Get Core")
                            .font(.custom("HelveticaNeue-Bold", size: 17))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 12)

                    Text("Subscription auto-renews. Cancel anytime.")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(Color(white: 0.25))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)

                    HStack(spacing: 32) {
                        Button {
                            Task {
                                let restored = await viewModel.restorePurchases()
                                if restored {
                                    await MainActor.run {
                                        onboardingConfirmationTier = viewModel.activeTier
                                        showOnboardingConfirmation = true
                                    }
                                } else {
                                    await MainActor.run {
                                        purchaseErrorMessage = "No active subscription found for this Apple ID."
                                        showPurchaseError = true
                                    }
                                }
                            }
                        } label: {
                            Text("Restore").font(.custom("Poppins-Regular", size: 12)).foregroundColor(Color(white: 0.25))
                        }
                        .buttonStyle(PlainButtonStyle())
                        Button {
                            if let url = URL(string: "https://creative-sailfish-dc6.notion.site/privacy-policy-3647cd351f5b807b9021d48d42a71a0b?source=copy_link") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("Privacy").font(.custom("Poppins-Regular", size: 12)).foregroundColor(Color(white: 0.25))
                        }
                        .buttonStyle(PlainButtonStyle())
                        Button {
                            if let url = URL(string: "https://creative-sailfish-dc6.notion.site/Terms-and-conditions-3647cd351f5b8000b482d1062d00f0ad?source=copy_link") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("Terms").font(.custom("Poppins-Regular", size: 12)).foregroundColor(Color(white: 0.25))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, isPad ? 40 : 0)
            .padding(.bottom, 80)
            .safeAreaInset(edge: .top) { Color.clear.frame(height: 0) }
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 0) }
            .overlay(alignment: .topTrailing) {
                Button {
                    PostHogSDK.shared.capture("paywall_skipped")
                    advanceNoHistory()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(white: 0.5))
                }
                .padding(.trailing, 24)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onAppear {
            PostHogSDK.shared.capture("paywall_viewed")
            Task {
                await viewModel.fetchOfferings()
                if let pro = viewModel.currentOffering?.availablePackages.first(where: { $0.storeProduct.productIdentifier == "com.brainla.bomb.pro.annual.v2" }) {
                    paywallProPrice = pro.storeProduct.localizedPriceString
                    paywallProMonthly = pro.storeProduct.localizedPricePerMonth ?? paywallProMonthly
                }
                if let core = viewModel.currentOffering?.availablePackages.first(where: { $0.storeProduct.productIdentifier == "com.brainla.bomb.core.sixmonths.v2" }) {
                    paywallCorePrice = core.storeProduct.localizedPriceString
                    paywallCoreMonthly = core.storeProduct.localizedPricePerMonth ?? paywallCoreMonthly
                }
                #if DEBUG
                switch UserDefaults.standard.string(forKey: "debug_currencyPreview") ?? "off" {
                case "USD": paywallProPrice = "$99.99";      paywallCorePrice = "$59.99";   paywallProMonthly = "$8.33";    paywallCoreMonthly = "$10.00"
                case "GBP": paywallProPrice = "£79.99";      paywallCorePrice = "£49.99";   paywallProMonthly = "£6.67";    paywallCoreMonthly = "£8.33"
                case "SGD": paywallProPrice = "S$129.99";    paywallCorePrice = "S$79.99";  paywallProMonthly = "S$10.83";  paywallCoreMonthly = "S$13.33"
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
        .fullScreenCover(isPresented: $showOnboardingConfirmation) {
            PaymentConfirmationView(tier: onboardingConfirmationTier) {
                showOnboardingConfirmation = false
                advanceNoHistory()
            }
        }
    }

    private func pwPlanCard(_ idx: Int, _ title: String, _ price: String, _ badge: String, _ features: [String] = [], _ billingLine: String = "", _ mostPopular: Bool = false) -> some View {
        let sel = selectedPlan == idx
        return Button { selectedPlan = idx } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.custom("HelveticaNeue", size: 15))
                        .foregroundColor(.white)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(price).font(.custom("HelveticaNeue-Bold", size: 16)).foregroundColor(.white)
                        Text(badge).font(.custom("Poppins-Regular", size: 11)).foregroundColor(Color(white: 0.55))
                    }
                }
                if sel && !features.isEmpty {
                    Spacer().frame(height: 2)
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(features, id: \.self) { feature in
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(Color(white: 0.42))
                                Text(feature)
                                    .font(.custom("Poppins-Regular", size: 12))
                                    .foregroundColor(Color(white: 0.52))
                            }
                        }
                    }
                    if !billingLine.isEmpty {
                        Text(billingLine)
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(Color(white: sel ? 0.12 : 0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(sel ? Color.white : Color(white: 0.15), lineWidth: sel ? 1.5 : 1))
            .overlay(alignment: .bottomTrailing) {
                if mostPopular && sel {
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
            .animation(.easeInOut(duration: 0.2), value: sel)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func pwTimelineRow(_ icon: String, _ filled: Bool, _ title: String, _ body: String, _ isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(filled ? .black : .white)
                    .frame(width: 34, height: 34)
                    .background(filled ? Color.white : Color(white: 0.12))
                    .clipShape(Circle())
                if !isLast {
                    Rectangle()
                        .fill(Color(white: 0.14))
                        .frame(width: 1, height: 44)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("HelveticaNeue-Bold", size: 15))
                    .foregroundColor(.white)
                Text(body)
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(Color(white: 0.42))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
            .padding(.bottom, isLast ? 0 : 12)
        }
    }

    // MARK: Step 12 — black transition

    private var blackTransitionView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("Some not so great news, and some great news.")
                .font(.custom("Poppins-Regular", size: 19))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(blackPhase >= 1 ? 1 : 0)
        }
        .onAppear {
            blackPhase = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.65)) { blackPhase = 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.easeInOut(duration: 0.8)) { blackPhase = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { advanceNoHistory() }
            }
        }
    }

    // MARK: Step 14 — bad news

    private var badNewsView: some View {
        let quotes = ["\"maybe later.\"", "\"what if i'm wrong.\"", "\"i'll do it later.\""]
        return ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                VStack(alignment: .leading, spacing: 20) {

                    (Text("The bad news is that you'll lose ")
                        .font(.custom("HelveticaNeue-Light", size: 20))
                        .foregroundColor(.white.opacity(0.7))
                    + Text(displayedMomentsNumber)
                        .font(.custom("HelveticaNeue-Light", size: 20))
                        .foregroundColor(Color(red: 0.27, green: 0.84, blue: 0.85))
                    + Text(" moments in thinking")
                        .font(.custom("HelveticaNeue-Light", size: 20))
                        .foregroundColor(.white.opacity(0.7)))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(badNewsPhase >= 1 ? 1 : 0)

                    ZStack(alignment: .leading) {
                        ForEach(0..<quotes.count, id: \.self) { i in
                            let curr = badNewsQuotePhrase % quotes.count
                            let prev = (badNewsQuotePhrase - 1 + quotes.count) % quotes.count
                            Text(quotes[i])
                                .font(.custom("HelveticaNeue", size: 20))
                                .foregroundColor(.white.opacity(0.5))
                                .opacity(curr == i ? 1 : 0)
                                .offset(y: curr == i ? 0 : (prev == i ? -20 : 20))
                                .animation(.easeInOut(duration: 0.4), value: badNewsQuotePhrase)
                        }
                    }
                    .frame(height: 28)
                    .opacity(badNewsPhase >= 2 ? 1 : 0)

                    Text("Meaning that you'll spend")
                        .font(.custom("HelveticaNeue-Light", size: 20))
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(badNewsPhase >= 3 ? 1 : 0)

                    Text(personYearsLabel)
                        .font(.custom("HelveticaNeue-UltraLight", size: 72))
                        .foregroundColor(.white)
                        .tracking(2)
                        .opacity(badNewsPhase >= 4 ? 1 : 0)

                    Text("Of your life hesitating. Overthinking.\nYep — just for deciding.")
                        .font(.custom("HelveticaNeue", size: 20))
                        .foregroundColor(.white.opacity(0.7))
                        .lineSpacing(5)
                        .opacity(badNewsPhase >= 5 ? 1 : 0)

                    Text("Most of it during the years\nyou were supposed to be living the most.")
                        .font(.custom("HelveticaNeue", size: 18))
                        .foregroundColor(.white.opacity(0.5))
                        .lineSpacing(5)
                        .italic()
                        .opacity(badNewsPhase >= 6 ? 1 : 0)
                }
                .padding(.horizontal, 36)
                Spacer()
                Text("Calculated from your answers and average deliberation research.")
                    .font(.custom("HelveticaNeue", size: 12))
                    .foregroundColor(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .lineSpacing(3)
                    .padding(.horizontal, 36)
                    .padding(.bottom, 14)
                    .opacity(badNewsPhase >= 7 ? 1 : 0)
                Button {
                    badNewsQuoteCycling = false
                    withAnimation(.easeInOut(duration: 0.4)) { badNewsDismissOpacity = 0 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { advanceNoHistory() }
                } label: {
                    Text("Continue")
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
                .opacity(badNewsPhase >= 7 ? 1 : 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack {
                Text("Tap to skip animation")
                    .font(.custom("HelveticaNeue", size: 11))
                    .foregroundColor(.white.opacity(0.25))
                    .padding(.top, 70)
                    .opacity(badNewsPhase < 7 ? 1 : 0)
                    .animation(.easeOut(duration: 0.25), value: badNewsPhase >= 7)
                Spacer()
            }
        }
        .opacity(badNewsDismissOpacity)
        .contentShape(Rectangle())
        .onTapGesture {
            guard badNewsPhase < 7 else { return }
            displayedMomentsNumber = personMomentsLabel
            if !badNewsQuoteCycling {
                badNewsQuoteCycling = true
                startQuoteCycle()
            }
            withAnimation(.easeIn(duration: 0.3)) { badNewsPhase = 7 }
        }
        .onAppear {
            badNewsPhase = 0
            badNewsDismissOpacity = 1
            badNewsQuotePhrase = 0
            displayedMomentsNumber = "000,000"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard badNewsPhase < 1 else { return }
                withAnimation(.easeIn(duration: 0.6)) { badNewsPhase = 1 }
                animateMomentsNumber()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                guard badNewsPhase < 2 else { return }
                withAnimation(.easeIn(duration: 0.5)) { badNewsPhase = 2 }
                badNewsQuoteCycling = true
                startQuoteCycle()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.3) {
                guard badNewsPhase < 3 else { return }
                withAnimation(.easeIn(duration: 0.6)) { badNewsPhase = 3 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.7) {
                guard badNewsPhase < 4 else { return }
                withAnimation(.easeIn(duration: 0.8)) { badNewsPhase = 4 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.9) {
                guard badNewsPhase < 5 else { return }
                withAnimation(.easeIn(duration: 0.6)) { badNewsPhase = 5 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.7) {
                guard badNewsPhase < 6 else { return }
                withAnimation(.easeIn(duration: 0.6)) { badNewsPhase = 6 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 7.9) {
                guard badNewsPhase < 7 else { return }
                withAnimation(.easeIn(duration: 0.6)) { badNewsPhase = 7 }
            }
        }
    }

    private func animateMomentsNumber() {
        var frame = 0
        let totalFrames = 22
        let finalValue = personMomentsLabel
        func tick() {
            if frame >= totalFrames || badNewsPhase >= 7 { displayedMomentsNumber = finalValue; return }
            let r = Int.random(in: 100000...999999)
            displayedMomentsNumber = "\(r / 1000),\(String(format: "%03d", r % 1000))"
            frame += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { tick() }
        }
        tick()
    }

    private func startQuoteCycle() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard badNewsQuoteCycling else { return }
            withAnimation(.easeInOut(duration: 0.4)) { badNewsQuotePhrase += 1 }
            startQuoteCycle()
        }
    }

    private func startGoodNewsRollingCycle() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            guard goodNewsRolling else { return }
            withAnimation(.easeInOut(duration: 0.4)) { rollingPhrase += 1 }
            startGoodNewsRollingCycle()
        }
    }

    // MARK: Step 15 — good news

    private var goodNewsView: some View {
        let rollingPhrases = ["clearer thinking.", "better decisions.", "more confidence.", "fewer regrets."]
        return ZStack {
            Color.black.ignoresSafeArea()

            // ── Variant A: left-aligned (default) ───────────────────────
            if goodNewsVariant == 0 {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    VStack(alignment: .leading, spacing: 20) {
                        Text("The good news is it doesn't have to stay that way.")
                            .font(.custom("HelveticaNeue-Light", size: 20))
                            .foregroundColor(.white.opacity(0.7))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(goodNewsPhase >= 1 ? 1 : 0)
                        // TODO: Replace "we" with final app name once decided
                        Text("We will help you spend less time stuck between decisions and more time moving toward:")
                            .font(.custom("HelveticaNeue", size: 20))
                            .foregroundColor(.white.opacity(0.6))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(goodNewsPhase >= 2 ? 1 : 0)
                        ZStack(alignment: .leading) {
                            let curr = rollingPhrase % rollingPhrases.count
                            let prev = (rollingPhrase - 1 + rollingPhrases.count) % rollingPhrases.count
                            ForEach(0..<rollingPhrases.count, id: \.self) { i in
                                Text(rollingPhrases[i])
                                    .font(.custom("HelveticaNeue-Light", size: 32))
                                    .foregroundColor(.white)
                                    .opacity(curr == i ? 1 : 0)
                                    .offset(y: curr == i ? 0 : (prev == i ? -20 : 20))
                                    .animation(.easeInOut(duration: 0.4), value: rollingPhrase)
                            }
                        }
                        .frame(height: 46)
                        .opacity(goodNewsPhase >= 3 ? 1 : 0)
                        Text("So more of your life\ngets spent living. Not hesitating.")
                            .font(.custom("HelveticaNeue", size: 20))
                            .foregroundColor(.white.opacity(0.7))
                            .lineSpacing(5)
                            .opacity(goodNewsPhase >= 4 ? 1 : 0)
                    }
                    .padding(.horizontal, 36)
                    Spacer()
                    Button {
                        goodNewsRolling = false
                        withAnimation(.easeInOut(duration: 0.4)) { goodNewsDismissOpacity = 0 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { advanceNoHistory() }
                    } label: {
                        Text("Unlock your brain")
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
                    .opacity(goodNewsPhase >= 5 ? 1 : 0)
                }
            }

            // ── Variant B: centered ───────────────────────────────────────
            if goodNewsVariant == 1 {
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 24) {
                        Text("The good news is it doesn't have to stay that way.")
                            .font(.custom("HelveticaNeue-Light", size: 20))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .opacity(goodNewsPhase >= 1 ? 1 : 0)
                        // TODO: Replace "we" with final app name once decided
                        Text("We will help you spend less time stuck\nbetween decisions and more time moving toward:")
                            .font(.custom("HelveticaNeue", size: 20))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .opacity(goodNewsPhase >= 2 ? 1 : 0)
                        ZStack {
                            ForEach(0..<rollingPhrases.count, id: \.self) { i in
                                Text(rollingPhrases[i])
                                    .font(.custom("HelveticaNeue-Light", size: 32))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .opacity(rollingPhrase == i ? 1 : 0)
                                    .offset(y: rollingPhrase == i ? 0 : (rollingPhrase > i ? -20 : 20))
                                    .animation(.easeInOut(duration: 0.4), value: rollingPhrase)
                            }
                        }
                        .frame(height: 46)
                        .opacity(goodNewsPhase >= 3 ? 1 : 0)
                        Text("So more of your life\ngets spent living. Not hesitating.")
                            .font(.custom("HelveticaNeue", size: 20))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .opacity(goodNewsPhase >= 4 ? 1 : 0)
                    }
                    .padding(.horizontal, 36)
                    Spacer()
                    Button {
                        goodNewsRolling = false
                        withAnimation(.easeInOut(duration: 0.4)) { goodNewsDismissOpacity = 0 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { advanceNoHistory() }
                    } label: {
                        Text("Unlock your brain")
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
                    .opacity(goodNewsPhase >= 5 ? 1 : 0)
                }
            }

            VStack {
                Text("Tap to skip animation")
                    .font(.custom("HelveticaNeue", size: 11))
                    .foregroundColor(.white.opacity(0.25))
                    .padding(.top, 70)
                    .opacity(goodNewsPhase < 5 ? 1 : 0)
                    .animation(.easeOut(duration: 0.25), value: goodNewsPhase >= 5)
                Spacer()
            }
        }
        .opacity(goodNewsDismissOpacity)
        .contentShape(Rectangle())
        .onTapGesture {
            guard goodNewsPhase < 5 else { return }
            if !goodNewsRolling {
                goodNewsRolling = true
                startGoodNewsRollingCycle()
            }
            withAnimation(.easeIn(duration: 0.3)) { goodNewsPhase = 5 }
        }
        .onAppear {
            goodNewsPhase = 0
            goodNewsDismissOpacity = 1
            rollingPhrase = 0
            goodNewsRolling = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                guard goodNewsPhase < 1 else { return }
                withAnimation(.easeIn(duration: 0.5)) { goodNewsPhase = 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                guard goodNewsPhase < 2 else { return }
                withAnimation(.easeIn(duration: 0.5)) { goodNewsPhase = 2 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                guard goodNewsPhase < 3 else { return }
                withAnimation(.easeIn(duration: 0.5)) { goodNewsPhase = 3 }
                goodNewsRolling = true
                startGoodNewsRollingCycle()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
                guard goodNewsPhase < 4 else { return }
                withAnimation(.easeIn(duration: 0.5)) { goodNewsPhase = 4 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
                guard goodNewsPhase < 5 else { return }
                withAnimation(.easeIn(duration: 0.4)) { goodNewsPhase = 5 }
            }
        }
    }

    // MARK: - Brand Intro

    private var brandIntroView: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                if useNumericIntro {
                    ForEach(numericParticles) { p in
                        Text(p.hex)
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundColor(.white)
                            .scaleEffect(p.currentScale)
                            .position(p.position)
                            .opacity(p.currentOpacity)
                            .allowsHitTesting(false)
                    }
                }
            }
            .onAppear {
                if useNumericIntro {
                    startNumericIntroAnimation(geo: geo)
                } else {
                    startBrandIntroAnimation(screenHeight: geo.size.height)
                }
            }
        }
    }


    private func startBrandIntroAnimation(screenHeight: CGFloat) {
        bracketWordOpacity = 1.0
        letterOpacities = Array(repeating: 0.0, count: 7)

        // Phase 0 — type "Bracket" char by char with a gentle fade-in per letter
        let word = Array("Bracket")
        for (i, char) in word.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.09) {
                typedBracketWord.append(char)
                withAnimation(.easeOut(duration: 0.22)) {
                    if i < letterOpacities.count { letterOpacities[i] = 1.0 }
                }
            }
        }
        // last char at 6 × 0.09 = 0.54s, fades complete by ~0.76s

        // Phase 1 — one soft "breath" pulse on the whole word (1.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.45)) { bracketWordOpacity = 0.55 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeInOut(duration: 0.4)) { bracketWordOpacity = 1.0 }
            }
        }

        // Phase 2 — brackets glide in with a damped spring, landing softly (1.85s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.85) {
            withAnimation(.easeIn(duration: 0.18)) {
                leftBracketOpacity = 1.0
                rightBracketOpacity = 1.0
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
                leftBracketX = -44
                rightBracketX = 44
            }
        }

        // Phase 3 — text fades while brackets pinch inward together (2.85s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.85) {
            withAnimation(.easeInOut(duration: 0.45)) {
                bracketWordOpacity = 0
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                leftBracketX = -14
                rightBracketX = 14
            }
        }

        // Phase 4 — settle to top with a slow, organic spring (3.55s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.55) {
            withAnimation(.spring(response: 0.85, dampingFraction: 0.82)) {
                brandLogoScale = 0.72
                brandLogoYOffset = -(screenHeight * 0.47)
            }
        }

        // Complete (4.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.3) {
            showBrandIntro = false
        }
    }

    // MARK: - Numeric "probability" intro (Version B)

    private func startNumericIntroAnimation(geo: GeometryProxy) {
        bracketWordOpacity = 0
        leftBracketOpacity = 0
        rightBracketOpacity = 0
        brandLogoScale = 1.0
        brandLogoYOffset = 0
        typedBracketWord = ""
        letterOpacities = Array(repeating: 1.0, count: 7)
        leftBracketX = -14
        rightBracketX = 14

        let w = geo.size.width
        let h = geo.size.height
        let centerX = w / 2

        let hexBank = ["00", "01", "29", "3B", "5E", "67", "7F", "8F",
                       "A3", "C3", "ED", "FD", "FF", "61", "76", "04",
                       "45", "B2", "D4", "1A", "9C", "2E", "8B", "F1"]

        // ── Uniform grid covering the whole screen ───────────────────────────
        let cellW: CGFloat = 24
        let cellH: CGFloat = 20
        let cols = max(12, Int(w / cellW))
        let rows = max(28, Int(h / cellH))
        let gridW = CGFloat(cols) * cellW
        let gridH = CGFloat(rows) * cellH
        let gridOriginX = (w - gridW) / 2 + cellW / 2
        let gridOriginY = (h - gridH) / 2 + cellH / 2

        // ── Bracket outline INSIDE the grid (in cell coordinates) ────────────
        // Each bracket = 4 cols wide, 14 rows tall. 2-col gap between [ and ].
        let bCols = 4
        let bRows = 14
        let bGap = 2
        let totalBW = bCols + bGap + bCols
        let leftStartCol = (cols - totalBW) / 2
        let rightStartCol = leftStartCol + bCols + bGap
        let topRow = (rows - bRows) / 2

        struct GridPos: Hashable { let row: Int; let col: Int }
        var bracketSet: Set<GridPos> = []

        // [ shape: top bar, bottom bar, left vertical (2 cols thick)
        for c in 0..<bCols { bracketSet.insert(GridPos(row: topRow, col: leftStartCol + c)) }
        for c in 0..<bCols { bracketSet.insert(GridPos(row: topRow + bRows - 1, col: leftStartCol + c)) }
        for r in 1..<(bRows - 1) {
            for c in 0..<2 { bracketSet.insert(GridPos(row: topRow + r, col: leftStartCol + c)) }
        }
        // ] shape: top bar, bottom bar, right vertical (2 cols thick on the right side)
        for c in 0..<bCols { bracketSet.insert(GridPos(row: topRow, col: rightStartCol + c)) }
        for c in 0..<bCols { bracketSet.insert(GridPos(row: topRow + bRows - 1, col: rightStartCol + c)) }
        for r in 1..<(bRows - 1) {
            for c in (bCols - 2)..<bCols { bracketSet.insert(GridPos(row: topRow + r, col: rightStartCol + c)) }
        }

        // Build a lookup of bracket cell screen positions
        func cellPos(_ row: Int, _ col: Int) -> CGPoint {
            CGPoint(
                x: gridOriginX + CGFloat(col) * cellW,
                y: gridOriginY + CGFloat(row) * cellH
            )
        }

        // For each non-bracket cell, find the nearest bracket cell (Manhattan)
        let bracketArray = Array(bracketSet)

        // ── Build particles ─────────────────────────────────────────────────
        var particles: [NumericIntroParticle] = []
        for r in 0..<rows {
            for c in 0..<cols {
                let here = GridPos(row: r, col: c)
                let isBracket = bracketSet.contains(here)
                let myPos = cellPos(r, c)
                let target: CGPoint
                if isBracket {
                    target = myPos
                } else {
                    var bestD = Int.max
                    var bestPos = myPos
                    for b in bracketArray {
                        let d = abs(b.row - r) + abs(b.col - c)
                        if d < bestD {
                            bestD = d
                            bestPos = cellPos(b.row, b.col)
                        }
                    }
                    target = bestPos
                }
                particles.append(NumericIntroParticle(
                    position: myPos,
                    targetPosition: target,
                    isBracketCell: isBracket,
                    hex: hexBank.randomElement() ?? "00",
                    currentOpacity: 0,
                    currentScale: 1.0
                ))
            }
        }
        numericParticles = particles

        // ── PHASE 0 (0–0.8s) — uniform grid fades in across whole screen ─────
        for i in 0..<numericParticles.count {
            let delay = 0.04 + Double.random(in: 0...0.7)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard i < numericParticles.count else { return }
                withAnimation(.easeIn(duration: 0.3)) {
                    let p = numericParticles[i]
                    numericParticles[i].currentOpacity = p.isBracketCell
                        ? Double.random(in: 0.55...0.85)
                        : Double.random(in: 0.35...0.7)
                }
            }
        }

        // ── PHASE 1 (1.2–4.0s) — STRICT L-PATH migration ────────────────────
        // Each non-bracket cell moves horizontally first (to bracket's column),
        // then vertically (to bracket's row). No diagonal motion ever.
        // Inner-ring cells start first so the bracket appears to absorb its
        // surroundings, then the wave propagates outward.
        let secondsPerCell: Double = 0.05
        for i in 0..<numericParticles.count {
            let p = numericParticles[i]
            if p.isBracketCell { continue }
            let dx = p.targetPosition.x - p.position.x
            let dy = p.targetPosition.y - p.position.y
            let cellsH = abs(dx) / cellW
            let cellsV = abs(dy) / cellH
            let manhattan = Double(cellsH + cellsV)
            let hDuration = max(0.08, Double(cellsH) * secondsPerCell)
            let vDuration = max(0.08, Double(cellsV) * secondsPerCell)
            // Closer rings start first, outer rings start later → "drain" feel
            let delay = 1.2 + manhattan * 0.04

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard i < numericParticles.count else { return }
                let p2 = numericParticles[i]
                // Step 1 — horizontal slide only
                withAnimation(.linear(duration: hDuration)) {
                    numericParticles[i].position.x = p2.targetPosition.x
                }
                // Step 2 — vertical slide only, fading as we arrive
                DispatchQueue.main.asyncAfter(deadline: .now() + hDuration) {
                    guard i < numericParticles.count else { return }
                    withAnimation(.linear(duration: vDuration)) {
                        numericParticles[i].position.y = numericParticles[i].targetPosition.y
                        numericParticles[i].currentOpacity = 0
                    }
                }
            }
        }

        // ── PHASE 1b (3.6s) — bracket cells lock to full brightness ──────────
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
            for i in 0..<numericParticles.count where numericParticles[i].isBracketCell {
                withAnimation(.easeIn(duration: 0.45)) {
                    numericParticles[i].currentOpacity = 0.95
                }
            }
        }

        // ── PHASE 2 (4.2s) — PULSE: bracket digits bloom to full white ───────
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
            for i in 0..<numericParticles.count where numericParticles[i].isBracketCell {
                withAnimation(.easeOut(duration: 0.22)) {
                    numericParticles[i].currentOpacity = 1.0
                    numericParticles[i].currentScale = 1.45
                }
            }
        }

        // ── PHASE 3 (4.55s) — crystallize: digits dissolve, solid BracketShape forms in place ──
        // BracketShape natural size = 24×70 (1 : 2.92, same as digit bracket).
        // At scale = bracketPixelH / 70 = 4 (for the standard grid), the shape
        // renders at exactly bracketPixelW × bracketPixelH on screen.
        let leftBracketCenterX = gridOriginX + (CGFloat(leftStartCol) + CGFloat(bCols - 1) / 2) * cellW
        let rightBracketCenterX = gridOriginX + (CGFloat(rightStartCol) + CGFloat(bCols - 1) / 2) * cellW
        let bracketPixelH = CGFloat(bRows) * cellH
        let bracketShapeNaturalH: CGFloat = 70
        let targetScale = bracketPixelH / bracketShapeNaturalH

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.55) {
            brandLogoScale = targetScale
            leftBracketX = (leftBracketCenterX - centerX) / targetScale
            rightBracketX = (rightBracketCenterX - centerX) / targetScale
            withAnimation(.easeIn(duration: 0.4)) {
                leftBracketOpacity = 1.0
                rightBracketOpacity = 1.0
            }
            for i in 0..<numericParticles.count where numericParticles[i].isBracketCell {
                withAnimation(.easeOut(duration: 0.42)) {
                    numericParticles[i].currentOpacity = 0
                    numericParticles[i].currentScale = 1.0
                }
            }
        }

        // ── PHASE 4 (5.3s) — solid [ ] shrinks and rides to the top corner ───
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.3) {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.85)) {
                brandLogoScale = 0.72
                brandLogoYOffset = -(h * 0.47)
                leftBracketX = -18
                rightBracketX = 18
            }
        }

        // ── DONE (6.4s) ──
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.4) {
            showBrandIntro = false
            numericParticles = []
        }
    }

    // MARK: - Flow

    private func startTyping() {
        typingGeneration += 1
        let gen = typingGeneration
        contentVisible = false
        let specialSteps = [12, 13, 14, 15, 16, 17, 18, 19, 20, 21]
        if specialSteps.contains(step) { return }
        guard step < anchorTexts.count else { return }
        let name = userName.trimmingCharacters(in: .whitespaces)
        var text = anchorTexts[step]
        if !name.isEmpty {
            if step == 11 { text = "building your brain, \(name)." }
        }
        typedText = ""
        let chars = Array(text)
        for (i, char) in chars.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.022) {
                guard typingGeneration == gen else { return }
                typedText.append(char)
                if i == chars.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        guard typingGeneration == gen else { return }
                        withAnimation(.easeIn(duration: 0.3)) { contentVisible = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            guard typingGeneration == gen else { return }
                            if step == 3 { nameFieldFocused = true }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            guard typingGeneration == gen else { return }
                            if step == 4 { ageFieldFocused = true }
                        }
                    }
                }
            }
        }
    }

    // Advance + record to memory
    private func advance(q: String, a: String) {
        guard !isTransitioning else { return }
        isTransitioning = true

        contentVisible = false
        var updated = history
        for i in 0..<updated.count { updated[i].age += 1 }
        updated.append(V2MemoryEntry(question: q, answer: a, age: 0))
        history = updated

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { typedText = "" }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isTransitioning = false
            step += 1
            UserDefaults.standard.set(step, forKey: Constants.onboardingProgressKey)
            PostHogSDK.shared.capture("onboarding_step_viewed", properties: [
                "step": step,
                "step_name": onboardingStepName(step)
            ])
            startTyping()
        }
    }

    // Advance without recording to memory
    private func advanceNoHistory() {
        guard !isTransitioning else { return }
        isTransitioning = true

        withAnimation(.easeOut(duration: 0.22)) { contentVisible = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) { typedText = "" }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
            isTransitioning = false
            if step >= 22 {
                UserDefaults.standard.removeObject(forKey: Constants.onboardingProgressKey)
                onComplete()
                return
            }
            withAnimation(.easeInOut(duration: 0.4)) { step += 1 }
            UserDefaults.standard.set(step, forKey: Constants.onboardingProgressKey)
            PostHogSDK.shared.capture("onboarding_step_viewed", properties: [
                "step": step,
                "step_name": onboardingStepName(step)
            ])
            startTyping()
        }
    }

    // Shared helper: push Q&A to history, type reflection, hold, advance
    private func showReflectionAndAdvance(q: String, a: String, reflection: String) {
        isTransitioning = true
        contentVisible = false
        var updated = history
        for j in 0..<updated.count { updated[j].age += 1 }
        updated.append(V2MemoryEntry(question: q, answer: a, age: 0))
        history = updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { typedText = "" }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            isTransitioning = false
            typingGeneration += 1
            let gen = typingGeneration
            let chars = Array(reflection)
            for (k, char) in chars.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(k) * 0.022) {
                    guard typingGeneration == gen else { return }
                    typedText.append(char)
                    if k == chars.count - 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            guard typingGeneration == gen else { return }
                            advance(q: reflection, a: "")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Analytics helpers

    private func onboardingStepName(_ s: Int) -> String {
        switch s {
        case 0: return "welcome"
        case 1: return "name"
        case 2: return "age"
        case 3: return "goal"
        case 4: return "decision_style"
        case 5: return "pressure"
        case 6: return "overthink"
        case 7: return "regret"
        case 8: return "clarity"
        case 9: return "confidence"
        case 10: return "relationships"
        case 11: return "work"
        case 12: return "money"
        case 13: return "health"
        case 14: return "values"
        case 15: return "risk_tolerance"
        case 16: return "support"
        case 17: return "interactive_demo"
        case 18: return "emotion_regulation"
        case 19: return "past_decisions"
        case 20: return "future_vision"
        case 21: return "commitment"
        case 22: return "complete"
        default: return "step_\(s)"
        }
    }

    // MARK: - UI helpers

    private func v2Button(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("HelveticaNeue", size: 16))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func v2Pill(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(selected ? .black : .white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 13)
                .padding(.horizontal, 17)
                .background(selected ? Color.white : Color(white: 0.07))
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .animation(.easeInOut(duration: 0.13), value: selected)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func v2RequestNotifications(completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if granted { NotificationManager.shared.scheduleDailyNotification() }
                completion()
            }
        }
    }
}

// MARK: - Memory model

private struct V2MemoryEntry: Identifiable, Equatable {
    let id = UUID()
    let question: String
    let answer: String
    var age: Int
}

// MARK: - Memory item view

private struct V2MemoryEntryView: View {
    let entry: V2MemoryEntry

    private let teal = Color(red: 0.18, green: 0.78, blue: 0.72)

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.question.replacingOccurrences(of: "\n", with: " "))
                .font(.custom("HelveticaNeue", size: 16))
                .foregroundColor(.white.opacity(questionOpacity))
                .lineLimit(2)
            if !entry.answer.isEmpty {
                Text(entry.answer)
                    .font(.custom("Poppins-Regular", size: 17))
                    .foregroundColor(teal.opacity(answerOpacity))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .blur(radius: blurAmount)
        .animation(.easeInOut(duration: 0.5), value: entry.age)
    }

    private var questionOpacity: Double {
        switch entry.age { case 0: return 0.70; case 1: return 0.35; default: return 0.14 }
    }
    private var answerOpacity: Double {
        switch entry.age { case 0: return 0.90; case 1: return 0.50; default: return 0.22 }
    }
    private var blurAmount: CGFloat {
        switch entry.age { case 0: return 0; case 1: return 1.5; default: return 3.5 }
    }
}
