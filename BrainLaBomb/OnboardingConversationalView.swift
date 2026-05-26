import SwiftUI
import UserNotifications

// MARK: - Private models

private enum ConvKind: Equatable {
    case button(String)
    case options([String])
    case consent
    case nameInput
    case ageInput
    case quizIntro
    case buildingBrain
    case beforeYouGo
    case badNews
    case goodNews
    case howItWorks
    case notifications
    case dualButton(String, String)
    case paywall
    case done
}

private struct ConvStep {
    let mainText: String
    let subText: String?
    let kind: ConvKind
}

private struct HistoryEntry: Identifiable {
    let id = UUID()
    let mainText: String
    let answer: String?
}

// MARK: - View

struct OnboardingConversationalView: View {
    var onComplete: () -> Void

    @State private var history: [HistoryEntry] = []
    @State private var stepIdx = 0

    // Typewriter
    @State private var typedMain = ""
    @State private var typedSub  = ""
    @State private var mainDone  = false
    @State private var showInteractions = false
    @State private var typingTask: Task<Void, Never>? = nil

    // Step-specific
    @State private var selectedOption: Int?    = nil
    @State private var visibleOptionCount      = 0
    @State private var selectedPlan: Int       = 2
    @State private var brainProgress: CGFloat  = 0
    @State private var brainReady              = false
    @State private var statBodyLines: [String] = []
    @State private var statBodyDone            = false
    
    // Name and Age
    @State private var userName: String = ""
    @State private var userAge: String = ""
    @State private var nameFieldFocused = false
    @State private var ageFieldFocused = false
    @State private var nameResponse = ""
    @State private var ageResponse = ""
    
    // Before you go
    @State private var beforeYouGoLines: [String] = []

    private let steps: [ConvStep] = [
        ConvStep(
            mainText: "you already know what you should do.",
            subText:  "you just need something to think it through with you.",
            kind: .button("i'm ready")
        ),
        ConvStep(
            mainText: "this isn't advice.",
            subText:  "it's your situation, run through thousands of possible outcomes. then handed back to you.",
            kind: .button("that's different")
        ),
        ConvStep(mainText: "before we begin.", subText: nil, kind: .consent),
        ConvStep(mainText: "what's your name?", subText: nil, kind: .nameInput),
        ConvStep(mainText: "how old are you?", subText: nil, kind: .ageInput),
        ConvStep(
            mainText: "i'm going to ask you a few questions.\nno need to overthink it.\nthen i'll start building your brain.",
            subText:  nil,
            kind: .quizIntro
        ),
        ConvStep(
            mainText: "how often do you face decisions you can't stop thinking about?",
            subText:  nil,
            kind: .options([
                "constantly — almost every day",
                "often — a few times a week",
                "sometimes — once in a while",
                "rarely — but when I do they're heavy"
            ])
        ),
        ConvStep(
            mainText: "what do you struggle with most?",
            subText:  nil,
            kind: .options([
                "knowing what I actually want",
                "overthinking every angle",
                "being too emotional to think clearly",
                "caring too much what others think"
            ])
        ),
        ConvStep(
            mainText: "when do you usually face these moments?",
            subText:  nil,
            kind: .options([
                "late at night when everything gets loud",
                "during big life changes",
                "when relationships get complicated",
                "when work and life collide"
            ])
        ),
        ConvStep(mainText: "building your brain.", subText: nil, kind: .buildingBrain),
        ConvStep(
            mainText: "how it works.",
            subText:  "describe what's on your mind. the brain runs your situation through thousands of angles, possibilities, and outcomes. then shows you what it found.",
            kind: .button("makes sense")
        ),
        ConvStep(
            mainText: "decisions don't only happen during business hours.",
            subText:  "let the brain find you when something's sitting with you.",
            kind: .notifications
        ),
        ConvStep(mainText: "ready.", subText: nil, kind: .done),
        ConvStep(mainText: "before you go.", subText: nil, kind: .beforeYouGo),
        ConvStep(mainText: "615,000", subText: nil, kind: .badNews),
        ConvStep(mainText: "9 out of 10 times", subText: nil, kind: .goodNews),
        ConvStep(mainText: "unlock your brain.", subText: nil, kind: .paywall),
        ConvStep(mainText: "you're ready.", subText: "bring it something real.", kind: .done),
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                if shouldShowHistory {
                    let recent = Array(history.suffix(2))
                    ForEach(Array(recent.enumerated()), id: \.element.id) { i, item in
                        let age = recent.count - i
                        historyRow(item, age: age)
                            .padding(.bottom, 28)
                            .transition(.asymmetric(
                                insertion: .identity,
                                removal: .modifier(
                                    active: ExitModifier(offset: -60, opacity: 0.3, blur: 2),
                                    identity: ExitModifier(offset: 0, opacity: 1, blur: 0)
                                )
                            ))
                    }
                }

                activeView
                    .id(stepIdx)
                    .transition(.asymmetric(
                        insertion: .modifier(
                            active: EntranceModifier(offset: 40, opacity: 0),
                            identity: EntranceModifier(offset: 0, opacity: 1)
                        ),
                        removal: .modifier(
                            active: ExitModifier(offset: -60, opacity: 0.3, blur: 2),
                            identity: ExitModifier(offset: 0, opacity: 1, blur: 0)
                        )
                    ))

                Spacer()
            }
            .padding(.horizontal, 28)
            .animation(.easeInOut(duration: 0.5), value: stepIdx)
            .animation(.easeInOut(duration: 0.5), value: history.count)
        }
        .onAppear { startTyping() }
    }

    // MARK: - shouldShowHistory

    private var shouldShowHistory: Bool {
        guard stepIdx < steps.count else { return true }
        switch steps[stepIdx].kind {
        case .badNews, .goodNews, .beforeYouGo: return false
        default: return true
        }
    }

    // MARK: - History row

    private func historyRow(_ item: HistoryEntry, age: Int) -> some View {
        let op: Double    = age == 1 ? 0.50 : 0.28
        let blur: CGFloat = age == 1 ? 2.5  : 5.0
        return VStack(alignment: .leading, spacing: 6) {
            Text(item.mainText)
                .font(.custom("HelveticaNeue", size: 17))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            if let ans = item.answer {
                Text(ans)
                    .font(.custom("HelveticaNeue", size: 16))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.leading)
            }
        }
        .opacity(op)
        .blur(radius: blur)
    }

    // MARK: - Active view

    private var activeView: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(typedMain)
                .font(activeMainFont)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineSpacing(isLargeStatStep ? 4 : 6)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !typedSub.isEmpty {
                Text(typedSub)
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.45))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(7)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if showInteractions, stepIdx < steps.count {
                interactionContent(for: steps[stepIdx])
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showInteractions)
    }

    private var activeMainFont: Font {
        isLargeStatStep
            ? .custom("HelveticaNeue-UltraLight", size: 72)
            : .custom("HelveticaNeue", size: 20)
    }

    private var isLargeStatStep: Bool {
        guard stepIdx < steps.count else { return false }
        switch steps[stepIdx].kind {
        case .badNews, .goodNews: return true
        default: return false
        }
    }

    // MARK: - Interaction content

    @ViewBuilder
    private func interactionContent(for step: ConvStep) -> some View {
        switch step.kind {

        case .button(let label):
            convButton(label) { advance(answer: nil) }

        case .quizIntro:
            Color.clear.frame(height: 0)
            
        case .nameInput:
            VStack(alignment: .leading, spacing: 12) {
                if nameResponse.isEmpty {
                    CustomTextField(
                        text: $userName,
                        placeholder: "",
                        onReturn: {
                            // Always advance, even with empty name
                            if !userName.trimmedOrEmpty {
                                let response = "\(userName). let's build something for you."
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    nameResponse = response
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    advance(answer: userName)
                                }
                            } else {
                                // Skip with empty name
                                advance(answer: nil)
                            }
                        }
                    )
                } else {
                    Text(nameResponse)
                        .font(.custom("HelveticaNeue", size: 16))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity)
                }
            }
            
        case .ageInput:
            VStack(alignment: .leading, spacing: 12) {
                if ageResponse.isEmpty {
                    CustomTextField(
                        text: $userAge,
                        placeholder: "",
                        keyboardType: .numberPad,
                        onReturn: {
                            if let age = Int(userAge) {
                                let response = ageReflection(for: age)
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    ageResponse = response
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    advance(answer: userAge)
                                }
                            }
                        }
                    )
                    .onChange(of: userAge) { newValue in
                        // Auto-advance when valid age is entered
                        if let age = Int(newValue), newValue.count >= 2 {
                            let response = ageReflection(for: age)
                            withAnimation(.easeInOut(duration: 0.3)) {
                                ageResponse = response
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                advance(answer: newValue)
                            }
                        }
                    }
                } else {
                    Text(ageResponse)
                        .font(.custom("HelveticaNeue", size: 16))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity)
                }
            }

        case .options(let opts):
            if let sel = selectedOption {
                Text(opts[sel])
                    .font(.custom("HelveticaNeue", size: 16))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            advance(answer: opts[sel])
                        }
                    }
            } else {
                VStack(spacing: 10) {
                    ForEach(0..<min(visibleOptionCount, opts.count), id: \.self) { i in
                        optionPill(opts[i]) {
                            withAnimation(.easeInOut(duration: 0.3)) { selectedOption = i }
                        }
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: visibleOptionCount)
            }

        case .consent:
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    consentPara("your thinks are processed by Claude AI. what you share leaves your device to generate a response.")
                    consentPara("we don't store your thinks. no servers. no profiles. no ads. everything stays between you and the brain.")
                    consentPara("the brain provides perspective. not instructions. all decisions remain entirely yours.")
                }
                VStack(spacing: 10) {
                    convButton("i understand and agree") {
                        UserDefaults.standard.set(true, forKey: "hasGivenAIConsent")
                        advance(answer: nil)
                    }
                    Button {
                        if let url = URL(string: "https://creative-sailfish-dc6.notion.site/privacy-policy-3647cd351f5b807b9021d48d42a71a0b") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("read our privacy policy")
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundColor(.white.opacity(0.3))
                            .underline()
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

        case .buildingBrain:
            VStack(alignment: .leading, spacing: 12) {
                if brainReady {
                    Text("trained for the way you think.")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.4))
                        .transition(.opacity)
                }
                Rectangle()
                    .fill(Color(white: 0.12))
                    .frame(height: 2)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(height: 2)
                            .scaleEffect(x: brainProgress, y: 1, anchor: .leading)
                    }
            }
            .animation(.easeInOut(duration: 0.4), value: brainReady)
            
        case .beforeYouGo:
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(beforeYouGoLines.enumerated()), id: \.offset) { _, line in
                    if line.isEmpty {
                        Color.clear.frame(height: 8)
                    } else {
                        Text(line)
                            .font(.custom("HelveticaNeue", size: 20))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .transition(.opacity)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.4), value: beforeYouGoLines.count)

        case .badNews:
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(statBodyLines.enumerated()), id: \.offset) { _, line in
                    if line.isEmpty {
                        Color.clear.frame(height: 8)
                    } else {
                        Text(line)
                            .font(.custom("Poppins-Regular", size: 15))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.leading)
                            .transition(.opacity)
                    }
                }
                if statBodyDone {
                    Button { advance(answer: nil) } label: {
                        Text("continue")
                            .font(.custom("HelveticaNeue", size: 14))
                            .tracking(2.5)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 16)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: statBodyLines.count)
            .animation(.easeInOut(duration: 0.4), value: statBodyDone)

        case .goodNews:
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(statBodyLines.enumerated()), id: \.offset) { _, line in
                    if line.isEmpty {
                        Color.clear.frame(height: 8)
                    } else {
                        Text(line)
                            .font(.custom("Poppins-Regular", size: 15))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.leading)
                            .transition(.opacity)
                    }
                }
                if statBodyDone {
                    convButton("unlock your brain") { advance(answer: nil) }
                        .padding(.top, 16)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: statBodyLines.count)
            .animation(.easeInOut(duration: 0.4), value: statBodyDone)
            
        case .howItWorks:
            convButton("makes sense") { advance(answer: nil) }

        case .notifications:
            VStack(spacing: 12) {
                convButton("yes, find me") { requestNotifications { advance(answer: nil) } }
                outlineButton("not yet") { advance(answer: nil) }
            }

        case .dualButton(let yes, let no):
            VStack(spacing: 12) {
                convButton(yes) { requestNotifications { advance(answer: nil) } }
                outlineButton(no) { advance(answer: nil) }
            }

        case .paywall:
            ScrollView(showsIndicators: false) {
                paywallContent
            }
            .frame(maxHeight: UIScreen.main.bounds.height * 0.68)

        case .done:
            convButton("let's go") {
                typingTask?.cancel()
                onComplete()
            }
        }
    }
    
    private func ageReflection(for age: Int) -> String {
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

    // MARK: - Consent helper

    private func consentPara(_ text: String) -> some View {
        Text(text)
            .font(.custom("Poppins-Regular", size: 13))
            .foregroundColor(.white.opacity(0.45))
            .lineSpacing(5)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Paywall

    private var paywallContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 10) {
                planCard(0, "FREE",  nil,           "5 thinks to start",     "try the brain",       "current", proTag: false, isFree: true)
                planCard(1, "CORE",  "$39.99",      "500 thinks · 6 months", "everything unlocked", nil,       proTag: false, isFree: false)
                planCard(2, "PRO",   "$99.99/year", "unlimited thinks",      "chat + full memory",  nil,       proTag: true,  isFree: false)
            }
            .padding(.bottom, 14)

            if selectedPlan == 2 {
                VStack(spacing: 10) {
                    Text("No Payment Due Today")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(Color(white: 0.4))
                        .frame(maxWidth: .infinity, alignment: .center)
                    VStack(spacing: 8) {
                        trialRow("Today", "Unlock everything. No charge.")
                        trialRow("Day 2", "Reminder before trial ends.")
                        trialRow("Day 3", "Billing starts unless cancelled.")
                    }
                }
                .padding(.bottom, 18)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 6)),
                    removal: .opacity
                ))
            }

            Group {
                if selectedPlan == 0 {
                    outlineButton("continue for free") { advance(answer: nil) }
                } else {
                    convButton(selectedPlan == 1 ? "get Core — $39.99" : "start my 3-day free trial") {
                        advance(answer: nil)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedPlan)
            .padding(.bottom, 10)

            HStack(spacing: 14) {
                Button { } label: {
                    Text("restore purchase")
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(Color(white: 0.3))
                }
                Text("·").foregroundColor(Color(white: 0.15))
                Button {
                    if let url = URL(string: "https://creative-sailfish-dc6.notion.site/Terms-and-conditions-3647cd351f5b8000b482d1062d00f0ad") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("terms")
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(Color(white: 0.3))
                }
                Text("·").foregroundColor(Color(white: 0.15))
                Button {
                    if let url = URL(string: "https://creative-sailfish-dc6.notion.site/privacy-policy-3647cd351f5b807b9021d48d42a71a0b") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("privacy")
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(Color(white: 0.3))
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 4)

            if selectedPlan == 2 {
                Text("3 days free, then $99.99/year. Cancel anytime.")
                    .font(.custom("Poppins-Regular", size: 10))
                    .foregroundColor(Color(white: 0.18))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 6)
            }
        }
    }

    private func planCard(_ index: Int, _ title: String, _ price: String?,
                          _ subtitle: String, _ detail: String, _ rightBadge: String?,
                          proTag: Bool, isFree: Bool) -> some View {
        let isSelected = selectedPlan == index
        return Button { selectedPlan = index } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.custom("HelveticaNeue", size: 14))
                            .foregroundColor(isFree ? Color(white: 0.3) : .white)
                        if proTag {
                            Text("3 DAYS FREE")
                                .font(.custom("Poppins-Regular", size: 9))
                                .foregroundColor(.black)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }
                    Text(subtitle)
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(isFree ? Color(white: 0.3) : Color(white: 0.4))
                    Text(detail)
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(isFree ? Color(white: 0.3) : Color(white: 0.4))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    if let price {
                        Text(price)
                            .font(.custom("HelveticaNeue", size: 13))
                            .foregroundColor(.white)
                    }
                    if let badge = rightBadge {
                        Text(badge)
                            .font(.custom("Poppins-Regular", size: 10))
                            .foregroundColor(Color(white: 0.3))
                    }
                }
            }
            .padding(14)
            .background(isSelected ? Color(white: 0.08) : Color(white: 0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color(white: 0.12), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func trialRow(_ day: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Text(day)
                .font(.custom("Poppins-Regular", size: 11))
                .foregroundColor(Color(white: 0.4))
                .frame(width: 40, alignment: .leading)
            Text(text)
                .font(.custom("Poppins-Regular", size: 11))
                .foregroundColor(Color(white: 0.6))
            Spacer()
        }
    }

    // MARK: - Buttons

    private func convButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("HelveticaNeue", size: 16))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func outlineButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func optionPill(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 13)
                .padding(.horizontal, 18)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Typewriter engine (word-by-word, 110ms per word)

    private func startTyping() {
        guard stepIdx < steps.count else { return }
        typingTask?.cancel()
        typedMain          = ""
        typedSub           = ""
        mainDone           = false
        showInteractions   = false
        selectedOption     = nil
        visibleOptionCount = 0
        brainReady         = false
        brainProgress      = 0
        statBodyLines      = []
        statBodyDone       = false
        nameResponse       = ""
        ageResponse        = ""
        beforeYouGoLines   = []

        var step = steps[stepIdx]
        
        // Special handling for brain complete screen - use name if available
        if stepIdx == 12 && !userName.trimmedOrEmpty {
            step = ConvStep(mainText: "ready, \(userName).", subText: nil, kind: .done)
        }

        typingTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)

            let mainWords = step.mainText.components(separatedBy: " ")
            for (i, word) in mainWords.enumerated() {
                if Task.isCancelled { return }
                if i > 0 { typedMain += " " }
                typedMain += word
                try? await Task.sleep(nanoseconds: 110_000_000)
            }
            mainDone = true

            if let sub = step.subText {
                try? await Task.sleep(nanoseconds: 220_000_000)
                let subWords = sub.components(separatedBy: " ")
                for (i, word) in subWords.enumerated() {
                    if Task.isCancelled { return }
                    if i > 0 { typedSub += " " }
                    typedSub += word
                    try? await Task.sleep(nanoseconds: 110_000_000)
                }
            }

            try? await Task.sleep(nanoseconds: 180_000_000)
            withAnimation(.easeInOut(duration: 0.4)) { showInteractions = true }

            switch step.kind {
            case .quizIntro:
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                if !Task.isCancelled { advance(answer: nil) }

            case .buildingBrain:
                withAnimation(.linear(duration: 2.0)) { brainProgress = 1.0 }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if Task.isCancelled { return }
                withAnimation(.easeInOut(duration: 0.4)) { brainReady = true }
                try? await Task.sleep(nanoseconds: 700_000_000)
                if !Task.isCancelled { advance(answer: nil) }
                
            case .beforeYouGo:
                // First line appears
                try? await Task.sleep(nanoseconds: 800_000_000)
                if Task.isCancelled { return }
                withAnimation(.easeInOut(duration: 0.4)) { beforeYouGoLines.append("") }
                
                // Second line appears
                try? await Task.sleep(nanoseconds: 500_000_000)
                if Task.isCancelled { return }
                withAnimation(.easeInOut(duration: 0.4)) { beforeYouGoLines.append("there's a bad news") }
                
                // Third line appears
                try? await Task.sleep(nanoseconds: 500_000_000)
                if Task.isCancelled { return }
                withAnimation(.easeInOut(duration: 0.4)) { beforeYouGoLines.append("and a good news.") }
                
                // Wait then advance
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                if !Task.isCancelled { advance(answer: nil) }

            case .badNews:
                // Show the number for 1.5 seconds first
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                
                // Then show lines one by one
                let badLines = [
                    "that's how many decisions",
                    "the average person will second-guess",
                    "in their lifetime.",
                    "",
                    "most of them already knew the answer.",
                    "they just couldn't hear it."
                ]
                for line in badLines {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    if Task.isCancelled { return }
                    withAnimation(.easeInOut(duration: 0.4)) { statBodyLines.append(line) }
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled {
                    withAnimation(.easeInOut(duration: 0.4)) { statBodyDone = true }
                }

            case .goodNews:
                // Show the text for 1.5 seconds first
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                
                // Then show lines one by one
                let goodLines = [
                    "the answer was already there.",
                    "",
                    "you just needed something",
                    "to help you hear it.",
                    "",
                    "that's what we built."
                ]
                for line in goodLines {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    if Task.isCancelled { return }
                    withAnimation(.easeInOut(duration: 0.4)) { statBodyLines.append(line) }
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled {
                    withAnimation(.easeInOut(duration: 0.4)) { statBodyDone = true }
                }

            case .options(let opts):
                for _ in opts {
                    try? await Task.sleep(nanoseconds: 80_000_000)
                    if Task.isCancelled { return }
                    withAnimation(.easeInOut(duration: 0.3)) { visibleOptionCount += 1 }
                }

            case .done:
                break

            default: break
            }
        }
    }

    // MARK: - Advance

    private func advance(answer: String?) {
        typingTask?.cancel()
        guard stepIdx < steps.count else { return }

        let step = steps[stepIdx]
        let skipHistory: Bool
        switch step.kind {
        case .quizIntro, .badNews, .goodNews, .beforeYouGo: skipHistory = true
        default: skipHistory = false
        }

        let displayText = brainReady ? "your brain is ready." : step.mainText

        // Special handling for "ready" screen - insert before you go screen before continuing
        if step.kind == .done && stepIdx == 12 {
            // This is the brain complete "ready" screen - go to before you go next
            withAnimation(.easeInOut(duration: 0.5)) {
                if !skipHistory {
                    history.append(HistoryEntry(mainText: displayText, answer: answer))
                }
                stepIdx = 13 // Jump to "before you go"
            }
        } else if step.kind == .beforeYouGo {
            // After before you go, go to bad news
            withAnimation(.easeInOut(duration: 0.5)) {
                stepIdx = 14 // Jump to bad news
            }
        } else if step.kind == .goodNews {
            // After good news, go to paywall
            withAnimation(.easeInOut(duration: 0.5)) {
                stepIdx = 16 // Jump to paywall
            }
        } else if step.kind == .paywall {
            // After paywall, go to final done
            withAnimation(.easeInOut(duration: 0.5)) {
                stepIdx = 17 // Jump to final done
            }
        } else {
            withAnimation(.easeInOut(duration: 0.5)) {
                if !skipHistory {
                    history.append(HistoryEntry(mainText: displayText, answer: answer))
                }
                stepIdx += 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            startTyping()
        }
    }

    // MARK: - Notifications

    private func requestNotifications(_ completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if granted { NotificationManager.shared.scheduleWeeklyNotification() }
                completion()
            }
        }
    }
}

// MARK: - Custom Transition Modifiers

private struct ExitModifier: ViewModifier {
    let offset: CGFloat
    let opacity: Double
    let blur: CGFloat
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
            .blur(radius: blur)
    }
}

private struct EntranceModifier: ViewModifier {
    let offset: CGFloat
    let opacity: Double
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
    }
}

// MARK: - Custom TextField

private struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    let onReturn: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(placeholder, text: $text)
                .font(.custom("HelveticaNeue", size: 18))
                .foregroundColor(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(keyboardType)
                .focused($isFocused)
                .onSubmit {
                    onReturn()
                }
            
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(height: 1)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
    }
}

// MARK: - String Extension

private extension String {
    var trimmedOrEmpty: Bool {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

