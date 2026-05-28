import SwiftUI
import UserNotifications

// MARK: - OnboardingViewV2
// One unified space. Every thought types in at the same anchor.
// History fades upward. No pages. No screen switches.

struct OnboardingViewV2: View {
    var onComplete: () -> Void

    @State private var step = 0
    @State private var history: [V2MemoryEntry] = []
    @State private var typedText = ""
    @State private var contentVisible = false
    @State private var isTransitioning = false

    @State private var userName = ""
    @State private var userAge = ""
    @State private var ageSubmitted = false
    @State private var quizSelections: [Int?] = [nil, nil, nil]
    @State private var selectedPlan: Int = 0
    @State private var buildProgress: CGFloat = 0
    @State private var buildDone = false

    @State private var blackPhase: Int = 0
    @State private var badNewsPhase: Int = 0
    @State private var goodNewsPhase: Int = 0
    @State private var rollingPhrase: Int = 0
    @State private var badNewsQuotePhrase: Int = 0
    @State private var displayedMomentsNumber: String = "000,000"
    @State private var goodNewsVariant: Int = 0
    @State private var badNewsQuoteCycling: Bool = false
    @State private var nudgePhase: Int = 0
    @State private var featuresPhase: Int = 0
    @State private var youreReadyPhase: Int = 0

    private let anchorTexts = [
        "You already know\nwhat you should do.",                            // 0
        "This isn't advice.",                                               // 1
        "before we begin.",                                                 // 2
        "what should I call you?",                                          // 3
        "how old are you?",                                                 // 4
        "how often do you face decisions\nyou can't stop thinking about?",  // 5
        "what do you struggle\nwith most?",                                 // 6
        "when do you usually\nface these moments?",                         // 7
        "building your brain.",                                             // 8
        "how it works.",                                                    // 9
        "",                                                                 // 10 full-screen black transition
        "",                                                                 // 11 full-screen Screen 1 (bad news)
        "",                                                                 // 12 full-screen Screen 2 (good news)
        "",                                                                 // 13 full-screen nudge/notifications
        "your brain\nis calibrated.",                                       // 14
        "",                                                                 // 15 full-screen features/value
        "",                                                                 // 16 full-screen paywall
        "you're ready."                                                     // 17
    ]

    private let quizReflections: [[String]] = [
        ["that means you're always carrying something.",
         "enough to know the feeling well.",
         "but when it hits it hits hard.",
         "the ones that matter always feel that way."],
        ["harder than it sounds. most people never figure it out.",
         "you already know the answer. you're building the case against it.",
         "emotion isn't the enemy. confusion is.",
         "you're deciding for an audience that isn't watching."],
        ["that's when the real thinking happens.",
         "when the stakes are highest the noise is loudest.",
         "the hardest decisions always involve someone else.",
         "the two things that were never supposed to mix."]
    ]

    private let quizOptions: [[String]] = [
        ["constantly — almost every day",
         "often — a few times a week",
         "sometimes — once in a while",
         "rarely — but when I do they're heavy"],
        ["knowing what I actually want",
         "overthinking every angle",
         "being too emotional to think clearly",
         "caring too much what others think"],
        ["late at night when everything gets loud",
         "during big life changes",
         "when relationships get complicated",
         "when work and life collide"]
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Color.black.ignoresSafeArea()

                // ── Memory zone ─────────────────────────────────────────────
                // Fixed height box, items bottom-aligned.
                // Natural layout spring displaces older items upward.
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
                // Anchor never moves. Every thought types in here.
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

                // ── Full-screen special steps ────────────────────────────────
                if step == 10 { blackTransitionView.transition(.opacity).zIndex(10) }
                if step == 11 { badNewsView.transition(.opacity).zIndex(10) }
                if step == 12 { goodNewsView.transition(.opacity).zIndex(10) }
                if step == 13 { nudgeView.transition(.opacity).zIndex(10) }
                if step == 15 { featuresView.transition(.opacity).zIndex(10) }
                if step == 16 { paywallView.transition(.opacity).zIndex(10) }
                if step == 17 { youreReadyView.transition(.opacity).zIndex(10) }

            }
            .animation(.easeInOut(duration: 0.45), value: step >= 10 && step <= 17)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear { startTyping() }
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
        case 6:  stepQuiz(index: 1)
        case 7:  stepQuiz(index: 2)
        case 8:  step8
        case 9:  step9
        case 14: step15
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
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                advance(q: anchorTexts[0], a: "")
            }
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
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                advance(q: anchorTexts[1], a: "")
            }
        }
    }

    // MARK: Step 2 — consent

    private var step2: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 12)
            Text("your answers may be processed by AI to generate your results.")
                .font(.custom("Poppins-Regular", size: 17))
                .foregroundColor(.white.opacity(0.40))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
            Spacer().frame(height: 30)
            v2Button("I understand and agree") {
                UserDefaults.standard.set(true, forKey: "hasGivenAIConsent")
                advance(q: anchorTexts[2], a: "agreed")
            }
            Spacer().frame(height: 10)
            HStack {
                Spacer()
                Button {
                    if let url = URL(string: "https://creative-sailfish-dc6.notion.site/privacy-policy-3647cd351f5b807b9021d48d42a71a0b") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("read our privacy policy")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.24))
                        .underline()
                }
                .buttonStyle(PlainButtonStyle())
                Spacer()
            }
        }
    }

    // MARK: Step 3 — name

    private var step3: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 12)
            ZStack(alignment: .leading) {
                if userName.isEmpty {
                    Text("your name")
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
                    .onSubmit { submitName() }
            }
            .padding(.vertical, 12)
            .overlay(
                Rectangle().fill(Color.white.opacity(0.16)).frame(height: 1),
                alignment: .bottom
            )
            Spacer().frame(height: 28)
            v2Button("continue") { submitName() }
                .opacity(userName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.28 : 1)
                .disabled(userName.trimmingCharacters(in: .whitespaces).isEmpty || isTransitioning)
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
                    Text("your age")
                        .font(.custom("HelveticaNeue", size: 21))
                        .foregroundColor(.white.opacity(0.20))
                }
                TextField("", text: $userAge)
                    .font(.custom("HelveticaNeue", size: 21))
                    .foregroundColor(.white)
                    .tint(.white)
                    .keyboardType(.numberPad)
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
                Text("this app is for ages 13 and above.")
                    .font(.custom("HelveticaNeue", size: 13))
                    .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4).opacity(0.85))
                    .padding(.top, 10)
                    .transition(.opacity)
            }
            Spacer().frame(height: 28)
            v2Button("continue") { submitAge() }
                .opacity(ageIsValid ? 1 : 0.28)
                .disabled(!ageIsValid || isTransitioning || ageSubmitted)
        }
        .animation(.easeInOut(duration: 0.2), value: ageTooLow)
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

        // Push age to history exactly like advance() does
        isTransitioning = true
        contentVisible = false
        var updated = history
        for i in 0..<updated.count { updated[i].age += 1 }
        updated.append(V2MemoryEntry(question: anchorTexts[4], answer: ageStr, age: 0))
        history = updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { typedText = "" }

        // After the history spring settles, type the reflection as the new anchor text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            isTransitioning = false
            let chars = Array(reflection)
            for (i, char) in chars.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.022) {
                    typedText.append(char)
                    if i == chars.count - 1 {
                        // Reflection springs up to history, then step 5 (first quiz) types in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            advance(q: reflection, a: "")
                        }
                    }
                }
            }
        }
    }

    // MARK: Steps 5–7 — quiz

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

                        // Push Q&A to history immediately
                        isTransitioning = true
                        contentVisible = false
                        var updated = history
                        for j in 0..<updated.count { updated[j].age += 1 }
                        updated.append(V2MemoryEntry(question: q, answer: a, age: 0))
                        history = updated
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { typedText = "" }

                        // Type reflection at anchor
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
            }
        }
    }

    // MARK: Step 8 — building brain

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
                Text("trained for the way you think.")
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

    // MARK: Step 9 — how it works

    private var step9: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 14)
            VStack(alignment: .leading, spacing: 0) {
                howBlock("01", "bring it anything.", "a decision. a feeling.\nsomething sitting with you.")
                Rectangle().fill(Color(white: 0.07)).frame(height: 1)
                howBlock("02", "the brain simulates it.", "thousands of outcomes.\nrun silently in seconds.")
                Rectangle().fill(Color(white: 0.07)).frame(height: 1)
                howBlock("03", "you get clarity.", "a verdict. the reasoning.\nwhat most outcomes showed.")
            }
            Spacer().frame(height: 26)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { advanceNoHistory() }
        }
    }

    private func howBlock(_ n: String, _ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(n).font(.custom("Poppins-Regular", size: 10)).foregroundColor(Color(white: 0.26))
            Text(title).font(.custom("HelveticaNeue", size: 18)).foregroundColor(.white)
            Text(body).font(.custom("Poppins-Regular", size: 13)).foregroundColor(.white.opacity(0.36)).lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 18)
    }

    // MARK: Step 13 — nudge / notifications

    private var nudgeView: some View {
        let teal = Color(red: 0.18, green: 0.78, blue: 0.72)
        return ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {

                // Title
                Spacer().frame(height: 64)
                Text("Allow the brain to nudge you.\nYou can always turn this off later.")
                    .font(.custom("HelveticaNeue-Bold", size: 24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 28)
                    .opacity(nudgePhase >= 1 ? 1 : 0)

                Spacer()

                // Mock iOS alert card
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\"the brain\" Would Like to\nSend You Notifications")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Notifications may include alerts, sounds, and icon badges. These can be configured in Settings.")
                            .font(.system(size: 13))
                            .foregroundColor(Color(white: 0.65))
                            .lineSpacing(3)
                        Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1).padding(.top, 4)
                        HStack(spacing: 0) {
                            Text("Don't Allow")
                                .font(.system(size: 15))
                                .foregroundColor(Color(white: 0.42))
                                .frame(maxWidth: .infinity)
                            Rectangle().fill(Color.white.opacity(0.15)).frame(width: 1, height: 40)
                            Text("Allow")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                        }
                        .frame(height: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .background(Color(white: 0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(teal, lineWidth: 2))

                    // Arrow pointing up toward Allow button
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.up")
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(teal)
                        Spacer().frame(width: 44)
                    }
                    .padding(.top, 12)
                }
                .padding(.horizontal, 28)
                .opacity(nudgePhase >= 2 ? 1 : 0)

                Spacer()

                // Continue button
                v2Button("Continue") {
                    v2RequestNotifications { advanceNoHistory() }
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

    // MARK: Step 14 — brain calibrated

    private var step15: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 12)
            Text("personalised to the way you think.")
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundColor(.white.opacity(0.30))
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { advanceNoHistory() }
        }
    }

    // MARK: Step 17 — you're ready (cinematic)

    private var youreReadyView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                Text("you're ready.")
                    .font(.custom("HelveticaNeue", size: 32))
                    .foregroundColor(.white)
                    .opacity(youreReadyPhase >= 1 ? 1 : 0)
                Spacer().frame(height: 14)
                Text("bring it something real.")
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { onComplete() }
            }
        }
    }

    // MARK: Step 15 — features/value

    private var featuresView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 24) {
                    Text("you're closer to clarity\nthan you think.")
                        .font(.custom("HelveticaNeue", size: 22))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .opacity(featuresPhase >= 1 ? 1 : 0)
                    Text("we help you see\nwhat emotion hides.")
                        .font(.custom("HelveticaNeue", size: 22))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .opacity(featuresPhase >= 2 ? 1 : 0)
                    Text("reasoning. tradeoffs. consequences.")
                        .font(.custom("HelveticaNeue", size: 22))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .opacity(featuresPhase >= 3 ? 1 : 0)
                    Text("before the decision\nbecomes regret.")
                        .font(.custom("HelveticaNeue", size: 22))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .opacity(featuresPhase >= 4 ? 1 : 0)
                }
                .padding(.horizontal, 36)
                Spacer()
                Button { advanceNoHistory() } label: {
                    Text("start your free trial")
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
                .opacity(featuresPhase >= 5 ? 1 : 0)
            }
        }
        .onAppear {
            featuresPhase = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 0.6)) { featuresPhase = 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                withAnimation(.easeIn(duration: 0.6)) { featuresPhase = 2 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                withAnimation(.easeIn(duration: 0.6)) { featuresPhase = 3 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                withAnimation(.easeIn(duration: 0.6)) { featuresPhase = 4 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.easeIn(duration: 0.6)) { featuresPhase = 5 }
            }
        }
    }

    // MARK: Step 16 — paywall

    private var paywallView: some View {
        let blue = Color(red: 0.22, green: 0.36, blue: 1.0)
        return ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Spacer so content starts below the fixed header
                    Spacer().frame(height: 100)

                    // Title
                    Text("Your Journey\nStarts Now")
                        .font(.custom("HelveticaNeue-Bold", size: 28))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                        .padding(.horizontal, 28)
                        .padding(.top, 28)

                    // Timeline
                    VStack(alignment: .leading, spacing: 0) {
                        pwTimelineRow("checkmark", true,  "Today: Brain calibrated",
                                      "Your thinking patterns are locked in.", false)
                        pwTimelineRow("lightbulb.fill", false, "Day 1: Your first think",
                                      "Bring it your first real decision.", false)
                        pwTimelineRow("chart.line.uptrend.xyaxis", false, "Day 3: Patterns emerge",
                                      "See how you decide and what drives you.", false)
                        pwTimelineRow("star.fill", false, "Day 7: Full clarity",
                                      "Unlimited thinks. Unlimited access.", true)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 32)

                    Spacer().frame(height: 32)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // Sticky bottom plan + CTA
                VStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("3 Days for $0.00")
                            .font(.custom("HelveticaNeue-Bold", size: 17))
                            .foregroundColor(.white)
                        Text("Then $99.99/year. Cancel anytime.")
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundColor(Color(white: 0.42))
                    }
                    .padding(.top, 22)

                    VStack(spacing: 8) {
                        pwPlanCard(0, "PRO — Unlimited", "$99.99/year", "3 Days Free")
                        pwPlanCard(1, "CORE",            "$39.99/6 months", "500 Thinks")
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 16)

                    Button { advanceNoHistory() } label: {
                        Text("Start My Free Trial")
                            .font(.custom("HelveticaNeue-Bold", size: 17))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(blue)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 28)
                    .padding(.top, 16)

                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(white: 0.36))
                        Text("No payment due now.")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(Color(white: 0.36))
                    }
                    .padding(.top, 12)

                    HStack(spacing: 18) {
                        Button {
                            if let u = URL(string: "https://creative-sailfish-dc6.notion.site/Terms-and-conditions-3647cd351f5b8000b482d1062d00f0ad") { UIApplication.shared.open(u) }
                        } label: { Text("Terms & Privacy").font(.custom("Poppins-Regular", size: 11)).foregroundColor(Color(white: 0.28)) }
                        .buttonStyle(PlainButtonStyle())
                        Button { advanceNoHistory() } label: {
                            Text("Skip for now").font(.custom("Poppins-Regular", size: 11)).foregroundColor(Color(white: 0.28))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 36)
                }
                .background(Color(white: 0.06))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }

            // Fixed header — stays on screen while content scrolls
            HStack {
                Button {} label: {
                    Text("Restore")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(Color(white: 0.40))
                }
                .buttonStyle(PlainButtonStyle())
                Spacer()
                Button { advanceNoHistory() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(white: 0.50))
                        .frame(width: 32, height: 32)
                        .background(Color(white: 0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 28)
            .padding(.top, 56)
            .background(Color.black)
            .zIndex(5)
        }
    }

    private func pwPlanCard(_ idx: Int, _ title: String, _ price: String, _ badge: String) -> some View {
        let sel = selectedPlan == idx
        return Button { selectedPlan = idx } label: {
            HStack {
                Text(title)
                    .font(.custom("HelveticaNeue", size: 15))
                    .foregroundColor(.white)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price).font(.custom("HelveticaNeue-Bold", size: 14)).foregroundColor(.white)
                    Text(badge).font(.custom("Poppins-Regular", size: 11)).foregroundColor(Color(white: 0.45))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(Color(white: sel ? 0.12 : 0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(sel ? Color.white : Color(white: 0.15), lineWidth: sel ? 1.5 : 1))
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
            }
            .padding(.top, 6)
            .padding(.bottom, isLast ? 0 : 12)
            Spacer()
        }
    }

    // MARK: Step 10 — black transition

    private var blackTransitionView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("some not so great news, and some great news.")
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

    // MARK: Step 11 — Screen 1 (bad news)

    private var badNewsView: some View {
        let quotes = ["\"maybe later.\"", "\"what if i'm wrong.\"", "\"i'll do it later.\""]
        return ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                VStack(alignment: .leading, spacing: 20) {

                    (Text("the bad news is that you'll lose ")
                        .font(.custom("HelveticaNeue-Light", size: 17))
                        .foregroundColor(.white.opacity(0.7))
                    + Text(displayedMomentsNumber)
                        .font(.custom("HelveticaNeue-Light", size: 17))
                        .foregroundColor(Color(red: 0.27, green: 0.84, blue: 0.85))
                    + Text(" moments in thinking")
                        .font(.custom("HelveticaNeue-Light", size: 17))
                        .foregroundColor(.white.opacity(0.7)))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(badNewsPhase >= 1 ? 1 : 0)

                    ZStack(alignment: .leading) {
                        ForEach(0..<quotes.count, id: \.self) { i in
                            let curr = badNewsQuotePhrase % quotes.count
                            let prev = (badNewsQuotePhrase - 1 + quotes.count) % quotes.count
                            Text(quotes[i])
                                .font(.custom("HelveticaNeue", size: 17))
                                .foregroundColor(.white.opacity(0.5))
                                .opacity(curr == i ? 1 : 0)
                                .offset(y: curr == i ? 0 : (prev == i ? -20 : 20))
                                .animation(.easeInOut(duration: 0.4), value: badNewsQuotePhrase)
                        }
                    }
                    .frame(height: 28)
                    .opacity(badNewsPhase >= 2 ? 1 : 0)

                    Text("meaning that you'll spend")
                        .font(.custom("HelveticaNeue-Light", size: 17))
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(badNewsPhase >= 3 ? 1 : 0)

                    Text(personYearsLabel)
                        .font(.custom("HelveticaNeue-UltraLight", size: 72))
                        .foregroundColor(.white)
                        .tracking(2)
                        .opacity(badNewsPhase >= 4 ? 1 : 0)

                    Text("of your life hesitating. overthinking.\nyep — just for deciding.")
                        .font(.custom("HelveticaNeue", size: 17))
                        .foregroundColor(.white.opacity(0.7))
                        .lineSpacing(5)
                        .opacity(badNewsPhase >= 5 ? 1 : 0)

                    Text("most of it during the years\nyou were supposed to be living the most.")
                        .font(.custom("HelveticaNeue", size: 15))
                        .foregroundColor(.white.opacity(0.5))
                        .lineSpacing(5)
                        .italic()
                        .opacity(badNewsPhase >= 6 ? 1 : 0)
                }
                .padding(.horizontal, 36)
                Spacer()
                Text("calculated from your answers and average deliberation research.")
                    .font(.custom("HelveticaNeue", size: 12))
                    .foregroundColor(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 36)
                    .padding(.bottom, 14)
                    .opacity(badNewsPhase >= 7 ? 1 : 0)
                Button {
                    badNewsQuoteCycling = false
                    withAnimation(.easeInOut(duration: 0.4)) { badNewsPhase = 0 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { advanceNoHistory() }
                } label: {
                    Text("continue")
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
        }
        .onAppear {
            badNewsPhase = 0
            badNewsQuotePhrase = 0
            displayedMomentsNumber = "000,000"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 0.6)) { badNewsPhase = 1 }
                animateMomentsNumber()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeIn(duration: 0.5)) { badNewsPhase = 2 }
                badNewsQuoteCycling = true
                startQuoteCycle()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.3) {
                withAnimation(.easeIn(duration: 0.6)) { badNewsPhase = 3 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.7) {
                withAnimation(.easeIn(duration: 0.8)) { badNewsPhase = 4 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.9) {
                withAnimation(.easeIn(duration: 0.6)) { badNewsPhase = 5 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.7) {
                withAnimation(.easeIn(duration: 0.6)) { badNewsPhase = 6 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 7.9) {
                withAnimation(.easeIn(duration: 0.6)) { badNewsPhase = 7 }
            }
        }
    }

    private func animateMomentsNumber() {
        var frame = 0
        let totalFrames = 22
        let finalValue = personMomentsLabel
        func tick() {
            if frame >= totalFrames { displayedMomentsNumber = finalValue; return }
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
            withAnimation(.easeInOut(duration: 0.4)) {
                badNewsQuotePhrase += 1
            }
            startQuoteCycle()
        }
    }

    // MARK: Step 12 — Screen 2 (good news)

    private var goodNewsView: some View {
        let rollingPhrases = ["clearer thinking.", "better decisions.", "more confidence.", "fewer regrets."]
        return ZStack {
            Color.black.ignoresSafeArea()

            // ── Variant A: left-aligned (default) ───────────────────────
            if goodNewsVariant == 0 {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    VStack(alignment: .leading, spacing: 20) {
                        Text("the good news is it doesn't have to stay that way.")
                            .font(.custom("HelveticaNeue-Light", size: 17))
                            .foregroundColor(.white.opacity(0.7))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(goodNewsPhase >= 1 ? 1 : 0)
                        // TODO: Replace "we" with final app name once decided
                        Text("we will help you spend less time stuck between decisions and more time moving toward:")
                            .font(.custom("HelveticaNeue", size: 17))
                            .foregroundColor(.white.opacity(0.6))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(goodNewsPhase >= 2 ? 1 : 0)
                        ZStack(alignment: .leading) {
                            ForEach(0..<rollingPhrases.count, id: \.self) { i in
                                Text(rollingPhrases[i])
                                    .font(.custom("HelveticaNeue-Light", size: 32))
                                    .foregroundColor(.white)
                                    .opacity(rollingPhrase == i ? 1 : 0)
                                    .offset(y: rollingPhrase == i ? 0 : (rollingPhrase > i ? -20 : 20))
                                    .animation(.easeInOut(duration: 0.4), value: rollingPhrase)
                            }
                        }
                        .frame(height: 46)
                        .opacity(goodNewsPhase >= 3 ? 1 : 0)
                        Text("so more of your life\ngets spent living. not hesitating.")
                            .font(.custom("HelveticaNeue", size: 17))
                            .foregroundColor(.white.opacity(0.7))
                            .lineSpacing(5)
                            .opacity(goodNewsPhase >= 4 ? 1 : 0)
                    }
                    .padding(.horizontal, 36)
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.4)) { goodNewsPhase = 0 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { advanceNoHistory() }
                    } label: {
                        Text("unlock your brain")
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

            // ── Variant B: centered (original) ───────────────────────────
            if goodNewsVariant == 1 {
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 24) {
                        Text("the good news is it doesn't have to stay that way.")
                            .font(.custom("HelveticaNeue-Light", size: 17))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .opacity(goodNewsPhase >= 1 ? 1 : 0)
                        // TODO: Replace "we" with final app name once decided
                        Text("we will help you spend less time stuck\nbetween decisions and more time moving toward:")
                            .font(.custom("HelveticaNeue", size: 17))
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
                        Text("so more of your life\ngets spent living. not hesitating.")
                            .font(.custom("HelveticaNeue", size: 17))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .opacity(goodNewsPhase >= 4 ? 1 : 0)
                    }
                    .padding(.horizontal, 36)
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.4)) { goodNewsPhase = 0 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { advanceNoHistory() }
                    } label: {
                        Text("unlock your brain")
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

        }
        .onAppear {
            goodNewsPhase = 0
            rollingPhrase = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 0.6)) { goodNewsPhase = 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                withAnimation(.easeIn(duration: 0.6)) { goodNewsPhase = 2 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
                withAnimation(.easeIn(duration: 0.6)) { goodNewsPhase = 3 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
                withAnimation(.easeInOut(duration: 0.4)) { rollingPhrase = 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.1) {
                withAnimation(.easeInOut(duration: 0.4)) { rollingPhrase = 2 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.1) {
                withAnimation(.easeInOut(duration: 0.4)) { rollingPhrase = 3 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.7) {
                withAnimation(.easeIn(duration: 0.6)) { goodNewsPhase = 4 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.7) {
                withAnimation(.easeIn(duration: 0.6)) { goodNewsPhase = 5 }
            }
        }
    }

    // MARK: - Flow

    private func startTyping() {
        contentVisible = false
        let specialSteps = [10, 11, 12, 13, 15, 16, 17]
        if specialSteps.contains(step) { return }
        guard step < anchorTexts.count else { return }
        let name = userName.trimmingCharacters(in: .whitespaces)
        var text = anchorTexts[step]
        if !name.isEmpty {
            if step == 8  { text = "building your brain, \(name)." }
            if step == 14 { text = "your brain\nis calibrated, \(name)." }
        }
        typedText = ""
        let chars = Array(text)
        for (i, char) in chars.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.022) {
                typedText.append(char)
                if i == chars.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeIn(duration: 0.3)) { contentVisible = true }
                    }
                }
            }
        }
    }

    // Advance + record to memory
    private func advance(q: String, a: String) {
        guard !isTransitioning else { return }
        isTransitioning = true

        // Instantly hide sub-content and add to history simultaneously —
        // the spring on the memory zone carries items upward, no fade-out blink.
        contentVisible = false
        var updated = history
        for i in 0..<updated.count { updated[i].age += 1 }
        updated.append(V2MemoryEntry(question: q, answer: a, age: 0))
        history = updated

        // Clear active text just after so history spring starts with text still briefly visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { typedText = "" }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            isTransitioning = false
            step += 1
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
            if step >= 18 { onComplete(); return }
            step += 1
            startTyping()
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

    private func planCard(_ idx: Int, _ title: String, _ price: String?,
                          _ subtitle: String, _ detail: String,
                          _ badge: String?, _ proBadge: Bool, _ free: Bool) -> some View {
        let sel = selectedPlan == idx
        return Button { selectedPlan = idx } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Text(title).font(.custom("HelveticaNeue", size: 13)).foregroundColor(free ? Color(white: 0.28) : .white)
                        if proBadge {
                            Text("3 DAYS FREE").font(.custom("Poppins-Regular", size: 9)).foregroundColor(.black)
                                .padding(.horizontal, 4).padding(.vertical, 2).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }
                    Text(subtitle).font(.custom("Poppins-Regular", size: 11)).foregroundColor(free ? Color(white: 0.28) : Color(white: 0.36))
                    Text(detail).font(.custom("Poppins-Regular", size: 11)).foregroundColor(free ? Color(white: 0.28) : Color(white: 0.36))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    if let p = price { Text(p).font(.custom("HelveticaNeue", size: 12)).foregroundColor(.white) }
                    if let b = badge { Text(b).font(.custom("Poppins-Regular", size: 10)).foregroundColor(Color(white: 0.26)) }
                }
            }
            .padding(13)
            .background(sel ? Color(white: 0.08) : Color(white: 0.04))
            .clipShape(RoundedRectangle(cornerRadius: 11))
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(sel ? Color.white : Color(white: 0.10), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func trialRow(_ day: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Text(day).font(.custom("Poppins-Regular", size: 10)).foregroundColor(Color(white: 0.32)).frame(width: 38, alignment: .leading)
            Text(text).font(.custom("Poppins-Regular", size: 10)).foregroundColor(Color(white: 0.52))
            Spacer()
        }
    }

    private func v2RequestNotifications(completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if granted { NotificationManager.shared.scheduleWeeklyNotification() }
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
                .font(.custom("HelveticaNeue", size: 13))
                .foregroundColor(.white.opacity(questionOpacity))
                .lineLimit(2)
            if !entry.answer.isEmpty {
                Text(entry.answer)
                    .font(.custom("Poppins-Regular", size: 14))
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
