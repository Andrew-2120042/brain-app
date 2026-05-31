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
    @State private var patternRevealContent: String = ""
    @State private var patternRevealLoaded: Bool = false
    @State private var patternRevealFailed: Bool = false
    @State private var patternDescriptionPhase: Int = 0
    @State private var patternContentAnimating: Bool = false
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
    @State private var howWeHelpPhase: Int = 0
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
        "what stops you from trusting\nyour instincts?",                    // 8
        "how long have you been sitting\nwith your most recent big decision?", // 9
        "right now — what best describes\nwhere you are?",                  // 10
        "building your brain.",                                             // 11
        "",                                                                 // 12 full-screen black transition
        "",                                                                 // 13 full-screen pattern reveal
        "",                                                                 // 14 full-screen bad news
        "",                                                                 // 15 full-screen good news
        "",                                                                 // 16 full-screen how we help
        "your brain\nis calibrated.",                                       // 17
        "",                                                                 // 18 full-screen features/value
        "",                                                                 // 19 full-screen paywall
        "",                                                                 // 20 full-screen nudge/notifications
        "you're ready."                                                     // 21
    ]

    private let quizReflections: [[String]] = [
        // Step 5 — frequency
        ["that means you're always carrying something.",
         "enough to know the feeling well.",
         "but when it hits it hits hard.",
         "the ones that matter always feel that way."],
        // Step 6 — struggle (Haiku-generated, these are fallbacks)
        ["harder than it sounds. most people never figure it out.",
         "you already know the answer. you're building the case against it.",
         "emotion isn't the enemy. confusion is.",
         "you're deciding for an audience that isn't watching."],
        // Step 7 — when
        ["that's when the real thinking happens.",
         "when the stakes are highest the noise is loudest.",
         "the hardest decisions always involve someone else.",
         "the two things that were never supposed to mix."],
        // Step 8 — why can't you trust your instincts
        ["being wrong once is survivable.\nstaying stuck forever isn't.",
         "you're deciding for an audience\nthat isn't watching as closely as you think.",
         "commitment isn't the problem.\nnot knowing if it's the right thing to commit to is.",
         "not knowing why you can't trust yourself\nis the most honest answer here."],
        // Step 9 — how long
        ["still fresh. the noise hasn't peaked yet.",
         "long enough that it's starting to feel permanent.\nit isn't.",
         "months of carrying something\nthat deserves an answer.",
         "that's not indecision.\nthat's a decision that's been waiting\nlonger than it should have."],
        // Step 10 — where are you
        ["both options feel right\nbecause you haven't run them forward yet.",
         "knowing and doing are separated\nby exactly one thing. trust.",
         "that's the most honest place to start from.",
         "processing and deciding aren't the same thing.\nyou need both.",
         "whatever it is — you brought it here.\nthat's enough to start."]
    ]

    private let quizOptions: [[String]] = [
        // Step 5
        ["constantly — almost every day",
         "often — a few times a week",
         "sometimes — once in a while",
         "rarely — but when I do they're heavy"],
        // Step 6
        ["knowing what I actually want",
         "overthinking every angle",
         "being too emotional to think clearly",
         "caring too much what others think"],
        // Step 7
        ["late at night when everything gets loud",
         "during big life changes",
         "when relationships get complicated",
         "when work and life collide"],
        // Step 8
        ["fear of being wrong",
         "fear of what others will think",
         "fear of commitment",
         "I don't know — that's the problem"],
        // Step 9
        ["a few days",
         "a few weeks",
         "months",
         "honestly I can't remember when it started"],
        // Step 10
        ["stuck between two options",
         "I know what I should do but can't do it",
         "completely lost — no idea what I want",
         "something happened and I need to process it",
         "something else — let me type it"]
    ]

    var body: some View {
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

                // ── Full-screen special steps ────────────────────────────────
                if step == 12 { blackTransitionView.transition(.opacity).zIndex(10) }
                if step == 13 { patternRevealView.transition(.opacity).zIndex(10) }
                if step == 14 { badNewsView.transition(.opacity).zIndex(10) }
                if step == 15 { goodNewsView.transition(.opacity).zIndex(10) }
                if step == 16 { howWeHelpView.transition(.opacity).zIndex(10) }
                if step == 18 { featuresView.transition(.opacity).zIndex(10) }
                if step == 19 { paywallView.transition(.opacity).zIndex(10) }
                if step == 20 { nudgeView.transition(.opacity).zIndex(10) }
                if step == 21 { youreReadyView.transition(.opacity).zIndex(10) }
            }
            .animation(.easeInOut(duration: 0.45), value: step >= 12 && step <= 21)
        }
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
        case 6:  step6MultiQuiz
        case 7:  step7MultiQuiz
        case 8:  step8MultiQuiz
        case 9:  stepQuiz(index: 4)
        case 10: step10WhereAreYou
        case 11: step8
        case 17: step15
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
            let chars = Array(reflection)
            for (i, char) in chars.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.022) {
                    typedText.append(char)
                    if i == chars.count - 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
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
                if step6ContinueVisible {
                    Spacer().frame(height: 16)
                    v2Button("continue") { handleStep6Continue() }
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
            if step7ContinueVisible {
                Spacer().frame(height: 16)
                v2Button("continue") { handleStep7Continue() }
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
            if step8ContinueVisible {
                Spacer().frame(height: 16)
                v2Button("continue") { handleStep8Continue() }
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
                            Text("tell me more...")
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
                    v2Button("done") { submitStep10() }
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

    // MARK: Step 13 — pattern reveal (full-screen)

    private var patternPercentage: String {
        let s0 = quizSelections[0]
        let s5 = quizSelections[5]
        if s0 == 0 && multiSelections8.contains(0) { return "73%" }
        if s0 == 0 && s5 == 1 { return "71%" }
        if s0 == 0 && multiSelections8.contains(1) { return "68%" }
        if s0 == 1 && s5 == 1 { return "67%" }
        if s0 == 1 && multiSelections8.contains(0) { return "64%" }
        if (quizSelections[4] == 2 || quizSelections[4] == 3) && s5 == 1 { return "64%" }
        if s5 == 2 { return "1 in 3" }
        if s5 == 3 { return "58%" }
        if s0 == 2 { return "61%" }
        if s0 == 3 { return "54%" }
        return "67%"
    }

    private var patternSourceLine: String {
        "drawn from people who answered exactly like you.\nthe percentage is drawn from your answer pattern."
    }

    private var patternRevealFallbackText: String {
        switch quizSelections[0] {
        case 0:
            return "of people who overthink constantly\nalready know what they should do.\n\nyou carry decisions with you constantly.\nyou've been sitting with this longer than you should.\nyou already know the answer — you just can't trust it yet.\n\nthat's not weakness.\nthat's the most common reason people stay stuck."
        case 1:
            return "of people who face this often\nshare your exact pattern.\n\nyou overthink more than most.\nyou've been going back and forth longer than feels right.\npart of what's keeping you stuck isn't the decision — it's the noise around it.\n\nthat's not overthinking.\nthat's caring about getting it right."
        case 2:
            return "of people who face this occasionally\nfeel it this heavily when they do.\n\nyou don't overthink everything.\njust the ones that matter.\nand when they matter — they really matter.\n\nthat's why the small decisions feel easy\nand the real ones feel impossible."
        case 3:
            return "of people who rarely face this\nfeel the weight of it this much when they do.\n\nyou don't do this often.\nbut when you do — it's real.\nthe rarest decisions carry the most weight.\n\nthat's not indecision.\nthat's knowing what actually matters."
        default:
            return "of people who face this often\nshare your exact pattern.\n\nyou overthink more than most.\nyou've been going back and forth longer than feels right.\npart of what's keeping you stuck isn't the decision — it's the noise around it.\n\nthat's not overthinking.\nthat's caring about getting it right."
        }
    }

    private var displayLines: [String] {
        let raw = patternRevealLoaded && !patternRevealContent.isEmpty
            ? patternRevealContent
            : patternRevealFallbackText
        return raw.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
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

        let lines = displayLines
        for i in 0..<lines.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.4) {
                withAnimation(.easeIn(duration: 0.3)) { patternDescriptionPhase = i + 1 }
            }
        }
        let afterLines = Double(lines.count) * 0.4 + 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + afterLines) {
            withAnimation(.easeIn(duration: 0.4)) { patternRevealPhase = 4 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + afterLines + 0.4 + 1.2) {
            withAnimation(.easeIn(duration: 0.4)) { patternRevealPhase = 5 }
        }
    }

    private var patternRevealView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()

                Text(patternPercentage)
                    .font(.custom("HelveticaNeue-UltraLight", size: 108))
                    .foregroundColor(.white)
                    .tracking(4)
                    .multilineTextAlignment(.center)
                    .opacity(patternRevealPhase >= 1 ? 1 : 0)
                    .animation(.easeIn(duration: 0.5), value: patternRevealPhase >= 1)

                if patternRevealPhase >= 3 {
                    VStack(spacing: 14) {
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
                            ForEach(Array(displayLines.enumerated()), id: \.offset) { i, line in
                                Text(line)
                                    .font(.custom("HelveticaNeue-Light", size: 16))
                                    .foregroundColor(.white.opacity(0.75))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .opacity(patternDescriptionPhase > i ? 1 : 0)
                                    .animation(.easeIn(duration: 0.3), value: patternDescriptionPhase)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 28)
                }

                Text("you're one of them.")
                    .font(.custom("HelveticaNeue-Light", size: 17))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.top, 22)
                    .opacity(patternRevealPhase >= 4 ? 1 : 0)
                    .animation(.easeIn(duration: 0.4), value: patternRevealPhase >= 4)

                Spacer()

                Button {
                    withAnimation(.easeOut(duration: 0.3)) { patternRevealPhase = 0 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { advanceNoHistory() }
                } label: {
                    Text("continue")
                        .font(.custom("HelveticaNeue", size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(2)
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(patternRevealPhase >= 5 ? 1 : 0)
                .animation(.easeIn(duration: 0.4), value: patternRevealPhase >= 5)

                Text(patternSourceLine)
                    .font(.custom("HelveticaNeue", size: 11))
                    .foregroundColor(.white.opacity(0.20))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                    .opacity(patternRevealPhase >= 2 ? 1 : 0)
                    .animation(.easeIn(duration: 0.4), value: patternRevealPhase >= 2)
            }
        }
        .onAppear {
            patternRevealPhase = 0
            patternRevealContent = ""
            patternRevealLoaded = false
            patternRevealFailed = false
            patternDescriptionPhase = 0
            patternContentAnimating = false
            loadingPulse = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeIn(duration: 0.5)) { patternRevealPhase = 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeIn(duration: 0.4)) { patternRevealPhase = 2 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
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
                    Text("how we help.")
                        .font(.custom("HelveticaNeue", size: 13))
                        .foregroundColor(Color(white: 0.30))
                        .padding(.bottom, 20)
                        .opacity(howWeHelpPhase >= 1 ? 1 : 0)
                    // TODO: Replace "we" in block 02 title with final app name once decided
                    howBlock("01", "bring it something real.", "a decision. a feeling.\nsomething stuck in your head.")
                        .opacity(howWeHelpPhase >= 1 ? 1 : 0)
                    Rectangle().fill(Color(white: 0.07)).frame(height: 1)
                        .opacity(howWeHelpPhase >= 2 ? 1 : 0)
                    howBlock("02", "we run it forward.", "outcomes. tradeoffs. consequences.\nquietly. in seconds.")
                        .opacity(howWeHelpPhase >= 2 ? 1 : 0)
                    Rectangle().fill(Color(white: 0.07)).frame(height: 1)
                        .opacity(howWeHelpPhase >= 3 ? 1 : 0)
                    howBlock("03", "you see farther.", "what keeps showing up.\nwhat emotion was hiding.")
                        .opacity(howWeHelpPhase >= 3 ? 1 : 0)
                }
                .padding(.horizontal, 36)
                Spacer()
                v2Button("continue") { advanceNoHistory() }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 52)
                    .opacity(howWeHelpPhase >= 4 ? 1 : 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            howWeHelpPhase = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeIn(duration: 0.5)) { howWeHelpPhase = 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeIn(duration: 0.5)) { howWeHelpPhase = 2 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeIn(duration: 0.5)) { howWeHelpPhase = 3 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
                withAnimation(.easeIn(duration: 0.5)) { howWeHelpPhase = 4 }
            }
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

    // MARK: Step 20 — nudge / notifications

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

    // MARK: Step 17 — brain calibrated

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

    // MARK: Step 21 — you're ready (cinematic)

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

    // MARK: Step 18 — features/value

    private var featuresView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 24) {
                    Text("you've already seen\nwhat hesitation costs.")
                        .font(.custom("HelveticaNeue", size: 22))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .opacity(featuresPhase >= 1 ? 1 : 0)
                    (Text("those ")
                        .font(.custom("HelveticaNeue", size: 22))
                    + Text(personYearsNumber)
                        .font(.custom("HelveticaNeue-Bold", size: 22))
                    + Text(" years\ndon't have to go that way.")
                        .font(.custom("HelveticaNeue", size: 22)))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .opacity(featuresPhase >= 2 ? 1 : 0)
                    Text("less time stuck.\nmore moments acted on.\nmore life actually lived.")
                        .font(.custom("HelveticaNeue", size: 22))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .opacity(featuresPhase >= 3 ? 1 : 0)
                    Text("so hesitation stops\ndeciding for you.")
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
                withAnimation(.easeIn(duration: 0.6)) { featuresPhase = 5 }
            }
        }
    }

    // MARK: Step 19 — paywall

    private var paywallView: some View {
        let blue = Color(red: 0.22, green: 0.36, blue: 1.0)
        return ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Text("your next decision\nchanges everything.")
                    .font(.custom("HelveticaNeue-Bold", size: 26))
                    .foregroundColor(.white)
                    .lineSpacing(4)
                    .padding(.top, 16)

                Text("spend less time stuck between\n\"what if\" and \"what now.\"")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(Color(white: 0.45))
                    .lineSpacing(4)
                    .padding(.top, 10)

                VStack(alignment: .leading, spacing: 0) {
                    pwTimelineRow("checkmark", true,  "today",
                                  "bring the decision\nyou can't stop thinking about.", false)
                    pwTimelineRow("lightbulb.fill", false, "day 3",
                                  "notice the patterns\nbehind your hesitation.", false)
                    pwTimelineRow("star.fill", false, "week 1+",
                                  "stop staying stuck.\nstart moving forward.", true)
                }
                .padding(.top, 16)

                Spacer()

                VStack(spacing: 4) {
                    Text("3 Days for $0.00")
                        .font(.custom("HelveticaNeue-Bold", size: 17))
                        .foregroundColor(.white)
                    Text("Then $99.99/year. Cancel anytime.")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(Color(white: 0.42))
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 8) {
                    pwPlanCard(0, "PRO — Unlimited", "$99.99/year", "3 Days Free",
                               ["unlimited thinks", "deeper simulations", "pattern memory", "faster reasoning"],
                               "billed annually")
                    pwPlanCard(1, "CORE", "$59 / 6 months", "500 Thinks",
                               ["500 thinks", "full simulation access", "pattern tracking"],
                               "billed every 6 months")
                }
                .padding(.top, 12)

                Button { advanceNoHistory() } label: {
                    Text("start my free trial")
                        .font(.custom("HelveticaNeue-Bold", size: 17))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 12)

                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(white: 0.36))
                    Text("3 days free. cancel anytime.")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(Color(white: 0.36))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                HStack(spacing: 18) {
                    Button {
                        if let u = URL(string: "https://creative-sailfish-dc6.notion.site/Terms-and-conditions-3647cd351f5b8000b482d1062d00f0ad") { UIApplication.shared.open(u) }
                    } label: { Text("Terms & Privacy").font(.custom("Poppins-Regular", size: 11)).foregroundColor(Color(white: 0.28)) }
                    .buttonStyle(PlainButtonStyle())
                    Button {} label: {
                        Text("Restore").font(.custom("Poppins-Regular", size: 11)).foregroundColor(Color(white: 0.28))
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button { advanceNoHistory() } label: {
                        Text("Skip for now").font(.custom("Poppins-Regular", size: 11)).foregroundColor(Color(white: 0.28))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func pwPlanCard(_ idx: Int, _ title: String, _ price: String, _ badge: String, _ features: [String] = [], _ billingLine: String = "") -> some View {
        let sel = selectedPlan == idx
        return Button { selectedPlan = idx } label: {
            VStack(alignment: .leading, spacing: 0) {
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
                if sel && !features.isEmpty {
                    Spacer().frame(height: 10)
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
            }
            .padding(.top, 6)
            .padding(.bottom, isLast ? 0 : 12)
            Spacer()
        }
    }

    // MARK: Step 12 — black transition

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

    // MARK: Step 14 — bad news

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
            withAnimation(.easeInOut(duration: 0.4)) { badNewsQuotePhrase += 1 }
            startQuoteCycle()
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

            // ── Variant B: centered ───────────────────────────────────────
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
        let specialSteps = [12, 13, 14, 15, 16, 18, 19, 20, 21]
        if specialSteps.contains(step) { return }
        guard step < anchorTexts.count else { return }
        let name = userName.trimmingCharacters(in: .whitespaces)
        var text = anchorTexts[step]
        if !name.isEmpty {
            if step == 11 { text = "building your brain, \(name)." }
            if step == 17 { text = "your brain\nis calibrated, \(name)." }
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

        contentVisible = false
        var updated = history
        for i in 0..<updated.count { updated[i].age += 1 }
        updated.append(V2MemoryEntry(question: q, answer: a, age: 0))
        history = updated

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
            if step >= 22 { onComplete(); return }
            step += 1
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
