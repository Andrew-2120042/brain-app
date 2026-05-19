import SwiftUI


struct StoriesView: View {
    let result: DecisionResult
    @ObservedObject var viewModel: AppViewModel
    var onContinueInChat: () -> Void = {}
    var onNewThink: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var progress: Double = 0
    @State private var isPaused = false
    @State private var timer: Timer?
    @State private var segStart: Date = Date()
    @State private var segElapsed: TimeInterval = 0
    @State private var touchStart: Date = Date()
    @State private var showTooltip = false
    @State private var reasoningDebug = false
    @State private var debugModeOverride: DecisionMode? = nil
    @State private var showPaywall = false
    @State private var debugForcePattern = false
    @State private var debugForceDoubleReasoning = false
    @State private var debugForceDoubleHistory = false
    @State private var reasoningAvailableHeight: CGFloat = 0
    @State private var historyAvailableHeight: CGFloat = 0

    private var activeMode: DecisionMode { debugModeOverride ?? result.mode }

    private var reasoningParagraph: String {
        #if DEBUG
        if debugForceDoubleReasoning {
            return "Night shifts rewire your sleep permanently over time. No holidays means your body never fully recovers. The money feels worth it now. Six months in, it won't. Your nervous system knows the difference between a hard season and a bad deal. The version of you that takes this job is not the version that thrives — it is the version that survives, and only barely. You already know this. The fact that you are still asking means part of you is hoping someone will give you permission to walk away. Here it is. Walk away. There is no version of this story where the tradeoff was worth it. People who took roles like this one almost always describe the same arc: first month feels manageable, third month feels heavy, sixth month feels like a trap. By then the money has been spent, the routine has calcified, and leaving feels harder than staying. Do not let that be you."
        }
        #endif
        let quotes = CharacterSet(charactersIn: "\"\u{201C}\u{201D}\u{2018}\u{2019}'")
        return result.report.reasoning.joined(separator: " ").trimmingCharacters(in: quotes)
    }

    private var reasoningFont: UIFont { UIFont(name: "HelveticaNeue", size: 22) ?? .systemFont(ofSize: 22) }
    private var reasoningAttrs: [NSAttributedString.Key: Any] {
        let ps = NSMutableParagraphStyle(); ps.lineSpacing = 6
        return [.font: reasoningFont, .paragraphStyle: ps]
    }
    private func measuredTextHeight(_ text: String, width: CGFloat) -> CGFloat {
        (text as NSString).boundingRect(
            with: CGSize(width: width, height: .infinity),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: reasoningAttrs, context: nil
        ).height
    }

    private var needsTwoReasoningCards: Bool {
        #if DEBUG
        if debugForceDoubleReasoning { return true }
        #endif
        guard reasoningAvailableHeight > 0 else { return false }
        return measuredTextHeight(reasoningParagraph, width: UIScreen.main.bounds.width - 56) > reasoningAvailableHeight
    }
    private var reasoningOffset: Int { needsTwoReasoningCards ? 1 : 0 }

    private var reasoningPart1: String {
        guard needsTwoReasoningCards, reasoningAvailableHeight > 0 else { return reasoningParagraph }
        let text = reasoningParagraph
        let w = UIScreen.main.bounds.width - 56
        var lo = 0, hi = text.count, fitCount = 0
        while lo <= hi {
            let mid = (lo + hi) / 2
            if measuredTextHeight(String(text.prefix(mid)), width: w) <= reasoningAvailableHeight {
                fitCount = mid; lo = mid + 1
            } else { hi = mid - 1 }
        }
        guard fitCount > 0 else { return String(text.prefix(text.count / 2)) }
        let prefix = String(text.prefix(fitCount))
        if let lastSpace = prefix.lastIndex(of: " ") { return String(prefix[..<lastSpace]) }
        return prefix
    }

    private var reasoningPart2: String {
        guard needsTwoReasoningCards else { return "" }
        return String(reasoningParagraph.dropFirst(reasoningPart1.count)).trimmingCharacters(in: .whitespaces)
    }

    private var isPaidTier: Bool {
        #if DEBUG
        return viewModel.debugTier == .core || viewModel.debugTier == .pro
        #else
        return false // TODO: RevenueCat
        #endif
    }

    private var canChat: Bool {
        #if DEBUG
        return viewModel.debugTier == .pro
        #else
        return false // TODO: RevenueCat
        #endif
    }

    private var historyInsightText: String {
        #if DEBUG
        if debugForceDoubleHistory {
            return "Every think you've done involves someone else's expectations sitting inside your decision. Your parents. Your girlfriend. Your manager. You frame your choices around what they need first and what you need second. That pattern is consistent enough now that it's worth naming. The people in your life aren't asking you to shrink — you are doing that preemptively, anticipating their needs before they even express them. That is not selflessness. That is a habit built from a time when it felt necessary. It may not be necessary anymore. The question is whether you are ready to find out what happens when you stop doing it."
        }
        #endif
        return viewModel.patternData?.historyInsight ?? ""
    }

    private var shouldShowHistoryCard: Bool {
        #if DEBUG
        if debugForceDoubleHistory { return true }
        #endif
        guard let patternData = viewModel.patternData else { return false }
        return !patternData.historyInsight.isEmpty
    }

    private var historyAttrs: [NSAttributedString.Key: Any] {
        let ps = NSMutableParagraphStyle(); ps.lineSpacing = 8
        return [.font: UIFont(name: "HelveticaNeue", size: 22) ?? .systemFont(ofSize: 22), .paragraphStyle: ps]
    }
    private func measuredHistoryHeight(_ text: String, width: CGFloat) -> CGFloat {
        (text as NSString).boundingRect(
            with: CGSize(width: width, height: .infinity),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: historyAttrs, context: nil
        ).height
    }
    private var needsTwoHistoryCards: Bool {
        #if DEBUG
        if debugForceDoubleHistory { return true }
        #endif
        guard shouldShowHistoryCard, historyAvailableHeight > 0 else { return false }
        return measuredHistoryHeight(historyInsightText, width: UIScreen.main.bounds.width - 56) > historyAvailableHeight
    }
    private var historyOffset: Int { needsTwoHistoryCards ? 1 : 0 }
    private var historyPart1: String {
        guard needsTwoHistoryCards, historyAvailableHeight > 0 else { return historyInsightText }
        let text = historyInsightText
        let w = UIScreen.main.bounds.width - 56
        var lo = 0, hi = text.count, fitCount = 0
        while lo <= hi {
            let mid = (lo + hi) / 2
            if measuredHistoryHeight(String(text.prefix(mid)), width: w) <= historyAvailableHeight {
                fitCount = mid; lo = mid + 1
            } else { hi = mid - 1 }
        }
        guard fitCount > 0 else { return String(text.prefix(text.count / 2)) }
        let prefix = String(text.prefix(fitCount))
        if let lastSpace = prefix.lastIndex(of: " ") { return String(prefix[..<lastSpace]) }
        return prefix
    }
    private var historyPart2: String {
        guard needsTwoHistoryCards else { return "" }
        return String(historyInsightText.dropFirst(historyPart1.count)).trimmingCharacters(in: .whitespaces)
    }

    private var totalCards: Int { (shouldShowHistoryCard ? 6 : 5) + reasoningOffset + historyOffset }
    private let storyDuration: TimeInterval = 7.0

    private var tooltipText: String {
        currentIndex == 1 + reasoningOffset
            ? "these percentages show how the\nmajority outcome breaks down across\ndifferent scenarios. they add up\nto roughly the confidence score."
            : "these are the minority outcomes.\nthe scenarios where the opposite\nhappened and why. always worth\nknowing both sides."
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // ── Card content ──────────────────────────────────────────────────
            Group {
                switch currentIndex {
                case 0: card1
                case 1 where needsTwoReasoningCards: card1b
                case 1 + reasoningOffset: card2
                case 2 + reasoningOffset: card3
                case 3 + reasoningOffset:
                    if isPaidTier { archetypeCard } else { blurredArchetypeCard }
                case 4 + reasoningOffset:
                    if shouldShowHistoryCard { historyInsightCard } else { patternCard }
                case 5 + reasoningOffset where needsTwoHistoryCards: historyInsightCard2
                default: patternCard
                }
            }
            .id(currentIndex)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: currentIndex)

            // ── Tap zones with pause / navigate ──────────────────────────────
            HStack(spacing: 0) {
                tapZone(onShortTap: {
                    if showTooltip { showTooltip = false } else { goBack() }
                })
                tapZone(onShortTap: {
                    if showTooltip { showTooltip = false } else { goForward() }
                })
            }

            // ── Paywall button (above tap zones so taps register) ────────────
            if !isPaidTier && (
                currentIndex == 3 + reasoningOffset ||
                (currentIndex == 4 + reasoningOffset && shouldShowHistoryCard) ||
                (currentIndex == 5 + reasoningOffset && needsTwoHistoryCards) ||
                currentIndex == totalCards - 1
            ) {
                VStack {
                    Spacer()
                    Button { showPaywall = true } label: {
                        Text("unlock pro →")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
            }

            // ── Chrome (sits above tap zones so buttons work) ─────────────────
            VStack(spacing: 0) {
                // Progress bars
                HStack(spacing: 4) {
                    ForEach(0..<totalCards, id: \.self) { i in
                        GeometryReader { geo in
                            Capsule().fill(Color(white: 0.22))
                                .overlay(
                                    Capsule().fill(Color.white)
                                        .frame(width: barWidth(i, geo.size.width),
                                               alignment: .leading),
                                    alignment: .leading
                                )
                        }
                        .frame(height: 2.5)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)

                // Buttons row
                HStack(alignment: .center, spacing: 0) {
                    #if DEBUG
                    let isHaiku = result.modelUsed.contains("haiku")
                    Text(isHaiku ? "HAIKU" : "SONNET")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(isHaiku ? .orange : Color(white: 0.4))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color(white: 0.12).clipShape(Capsule()))
                        .padding(.leading, 18)
                    #endif
                    Spacer()
                    // Info button (cards 2 & 3)
                    if (currentIndex == 1 + reasoningOffset || currentIndex == 2 + reasoningOffset) && (activeMode == .decision || activeMode == .direction) {
                        Button { showTooltip.toggle() } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 16))
                                .foregroundColor(Color(white: 0.45))
                                .frame(width: 40, height: 44)
                        }
                    }
                    // Close
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(white: 0.5))
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.trailing, 8)

                Spacer()

                if currentIndex == totalCards - 1 {
                    // ── Last card buttons ─────────────────────────────────────
                    VStack(spacing: 12) {
                        if canChat {
                            Button { onContinueInChat() } label: {
                                HStack {
                                    Text("continue in chat")
                                        .font(.custom("HelveticaNeue", size: 16))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 16)
                                .background(Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white, lineWidth: 1))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        Button { onNewThink() } label: {
                            Text("new think")
                                .font(.custom("HelveticaNeue", size: 16))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 36)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.25), value: currentIndex)
                } else {
                    // DEBUG: pause + reasoning layout toggle
                    HStack(spacing: 10) {
                        Button {
                            if isPaused { resumeIfNeeded() } else { pauseIfNeeded() }
                        } label: {
                            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(white: 0.55))
                                .frame(width: 36, height: 36)
                                .background(Color(white: 0.14))
                                .clipShape(Circle())
                        }
                        if currentIndex == 0 {
                            Button { reasoningDebug.toggle() } label: {
                                Image(systemName: reasoningDebug ? "text.aligncenter" : "text.alignleft")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(reasoningDebug ? Color.white : Color(white: 0.55))
                                    .frame(width: 36, height: 36)
                                    .background(reasoningDebug ? Color(white: 0.28) : Color(white: 0.14))
                                    .clipShape(Circle())
                            }
                        }
                        // Pattern debug: force pattern card to show full data
                        Button {
                            debugForcePattern.toggle()
                            #if DEBUG
                            if debugForcePattern && viewModel.patternData == nil {
                                viewModel.injectMockPatternData()
                            }
                            #endif
                        } label: {
                            Text("PAT")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(debugForcePattern ? Color.black : Color(white: 0.55))
                                .frame(width: 38, height: 28)
                                .background(debugForcePattern ? Color.white : Color(white: 0.14))
                                .clipShape(Capsule())
                        }
                        Button { viewModel.refreshPatternIfNeeded() } label: {
                            Text("PAT↺")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(white: 0.55))
                                .frame(width: 42, height: 28)
                                .background(Color(white: 0.14))
                                .clipShape(Capsule())
                        }
                        Button { debugForceDoubleReasoning.toggle() } label: {
                            Text("R2")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(debugForceDoubleReasoning ? Color.black : Color(white: 0.55))
                                .frame(width: 34, height: 28)
                                .background(debugForceDoubleReasoning ? Color.white : Color(white: 0.14))
                                .clipShape(Capsule())
                        }
                        Button { debugForceDoubleHistory.toggle() } label: {
                            Text("H2")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(debugForceDoubleHistory ? Color.black : Color(white: 0.55))
                                .frame(width: 34, height: 28)
                                .background(debugForceDoubleHistory ? Color.white : Color(white: 0.14))
                                .clipShape(Capsule())
                        }
                        // Mode override buttons
                        ForEach([DecisionMode.decision, .direction, .emotional], id: \.self) { mode in
                            let label = mode == .decision ? "D" : mode == .direction ? "Dir" : "E"
                            let isActive = debugModeOverride == mode
                            Button { debugModeOverride = isActive ? nil : mode } label: {
                                Text(label)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(isActive ? Color.black : Color(white: 0.55))
                                    .frame(width: 34, height: 28)
                                    .background(isActive ? Color.white : Color(white: 0.14))
                                    .clipShape(Capsule())
                            }
                        }
                        Spacer()
                    }
                    .padding(.leading, 20)
                    .padding(.bottom, 36)
                }
            }

            // ── Tooltip ───────────────────────────────────────────────────────
            if showTooltip {
                Color.clear
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { showTooltip = false }
                    .overlay(alignment: .topTrailing) {
                        Text(tooltipText)
                            .font(.custom("HelveticaNeue", size: 12))
                            .foregroundColor(Color(white: 0.72))
                            .multilineTextAlignment(.leading)
                            .padding(13)
                            .background(Color(white: 0.16))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.trailing, 20)
                            .padding(.top, 104)
                    }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 40)
                .onEnded { v in if v.translation.height > 60 { dismiss() } }
        )
        .onAppear { startProgress() }
        .onDisappear { stopTimer() }
        .fullScreenCover(isPresented: $showPaywall) { PaywallView() }
    }

    // ── Tap zone helper ───────────────────────────────────────────────────────
    // Uses DragGesture(minimumDistance:0) to detect hold vs tap.
    // Short touch (< 0.25 s) → navigate; long hold → pause while held.
    private func tapZone(onShortTap: @escaping () -> Void) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPaused else { return }
                        touchStart = Date()
                        pauseIfNeeded()
                    }
                    .onEnded { _ in
                        let held = Date().timeIntervalSince(touchStart)
                        resumeIfNeeded()
                        if held < 0.25 { onShortTap() }
                    }
            )
    }

    // MARK: – Card 1: Reasoning ───────────────────────────────────────────────

    private var card1: some View {
        Group {
            if reasoningDebug {
                VStack {
                    Spacer()
                    Text(reasoningParagraph)
                        .font(.custom("HelveticaNeue", size: 22))
                        .foregroundColor(.white)
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                    Spacer()
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    cardHeading("reasoning")
                        .padding(.top, 72)
                    Spacer().frame(height: 28)
                    Text(needsTwoReasoningCards ? reasoningPart1 : reasoningParagraph)
                        .font(.custom("HelveticaNeue", size: 22))
                        .foregroundColor(.white)
                        .lineSpacing(6)
                    Spacer()
                }
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .background(
            GeometryReader { geo in
                // Capture available text height once the card is laid out
                Color.clear.onAppear {
                    reasoningAvailableHeight = geo.size.height - 72 - 16 - 28 - 60
                }
            }
        )
    }

    // MARK: – Card 1b: Reasoning overflow ────────────────────────────────────

    private var card1b: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeading("reasoning, cont.")
                .padding(.top, 72)
            Spacer().frame(height: 28)
            Text(reasoningPart2)
                .font(.custom("HelveticaNeue", size: 22))
                .foregroundColor(.white)
                .lineSpacing(6)
            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: – Card 2 ──────────────────────────────────────────────────────────

    @ViewBuilder
    private var card2: some View {
        switch activeMode {
        case .decision:
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    cardHeading(result.isPositive ? "what this looks like" : "what goes wrong")
                        .padding(.top, 72)

                    Spacer().frame(height: 20)

                    Text("Within the \(result.confidence)%\nwho \(result.report.majorityLabel).")
                        .font(.custom("HelveticaNeue", size: 32))
                        .foregroundColor(.white)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer().frame(height: 22)

                    Rectangle()
                        .fill(Color(white: 0.18))
                        .frame(height: 1)

                    Spacer().frame(height: 28)

                    VStack(alignment: .leading, spacing: 26) {
                        ForEach(result.report.majorityOutcomes) { outcomeRow($0) }
                    }

                    Spacer().frame(height: 60)
                }
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .direction:
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    cardHeading("what most outcomes show")
                        .padding(.top, 72)

                    Spacer().frame(height: 20)

                    Text("Most outcomes that went well had this in common.")
                        .font(.custom("HelveticaNeue", size: 32))
                        .foregroundColor(.white)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer().frame(height: 22)

                    Rectangle()
                        .fill(Color(white: 0.18))
                        .frame(height: 1)

                    Spacer().frame(height: 28)

                    VStack(alignment: .leading, spacing: 26) {
                        ForEach(result.report.majorityOutcomes) { outcomeRow($0) }
                    }

                    Spacer().frame(height: 60)
                }
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .emotional:
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    cardHeading("what you're not saying")
                        .padding(.top, 72)

                    Spacer().frame(height: 28)

                    Text(result.report.whatYoureNotSaying.isEmpty
                        ? "The thing underneath what you described is usually something simpler. Fear of what it means. Or needing to know it mattered."
                        : result.report.whatYoureNotSaying)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer().frame(height: 60)
                }
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: – Card 3 ──────────────────────────────────────────────────────────

    @ViewBuilder
    private var card3: some View {
        switch activeMode {
        case .decision:
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    cardHeading("the other \(100 - result.confidence)%")
                        .padding(.top, 72)

                    Spacer().frame(height: 20)

                    Text("Some simulations\nwent the other way.")
                        .font(.custom("HelveticaNeue", size: 32))
                        .foregroundColor(.white)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer().frame(height: 10)

                    Text("Here's what those looked like.")
                        .font(.custom("HelveticaNeue", size: 14))
                        .foregroundColor(Color(white: 0.4))

                    Spacer().frame(height: 22)

                    Rectangle()
                        .fill(Color(white: 0.18))
                        .frame(height: 1)

                    Spacer().frame(height: 28)

                    VStack(alignment: .leading, spacing: 26) {
                        ForEach(result.report.minorityOutcomes) { outcomeRow($0) }
                    }

                    Spacer().frame(height: 60)
                }
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .direction:
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    cardHeading("what to watch for")
                        .padding(.top, 72)

                    Spacer().frame(height: 20)

                    Text("In the outcomes that struggled, this is what got in the way.")
                        .font(.custom("HelveticaNeue", size: 32))
                        .foregroundColor(.white)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer().frame(height: 22)

                    Rectangle()
                        .fill(Color(white: 0.18))
                        .frame(height: 1)

                    Spacer().frame(height: 28)

                    VStack(alignment: .leading, spacing: 26) {
                        ForEach(result.report.minorityOutcomes) { outcomeRow($0) }
                    }

                    Spacer().frame(height: 60)
                }
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .emotional:
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    cardHeading("what usually helps")
                        .padding(.top, 72)

                    Spacer().frame(height: 28)

                    Text(result.report.whatUsuallyHelps.isEmpty
                        ? "Most people in this spot need one thing first — to say out loud what they're actually scared of. Not to the other person. Just to themselves."
                        : result.report.whatUsuallyHelps)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer().frame(height: 60)
                }
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: – Card 4: Archetype ───────────────────────────────────────────────

    // MARK: – Card 4: Archetype ───────────────────────────────────────────────

    private var archetypeCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeading("archetype")
                .padding(.top, 72)
                .padding(.horizontal, 28)

            Spacer()

            VStack(alignment: .leading, spacing: 10) {
                Text(result.archetype.name)
                    .font(.custom("HelveticaNeue", size: 28))
                    .foregroundColor(.white)

                Text(result.archetype.description)
                    .font(.custom("HelveticaNeue", size: 18))
                    .foregroundColor(Color(white: 0.38))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)

            Spacer().frame(height: 40)

            Rectangle()
                .fill(Color(white: 0.18))
                .frame(height: 1)
                .padding(.horizontal, 28)

            Spacer().frame(height: 28)

            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(result.archetype.percentage)%")
                        .font(.custom("HelveticaNeue", size: 52))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text("your archetype")
                        .font(.custom("HelveticaNeue", size: 12))
                        .foregroundColor(Color(white: 0.42))
                }
                .frame(width: 100, alignment: .leading)

                Text("of thinkers approach decisions the same way you do.")
                    .font(.custom("HelveticaNeue", size: 13))
                    .foregroundColor(Color(white: 0.42))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 10)
            }
            .padding(.horizontal, 28)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var blurredArchetypeCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeading("archetype")
                .padding(.top, 72)
                .padding(.bottom, 24)

            Text(result.archetype.name)
                .font(.custom("HelveticaNeue", size: 38))
                .foregroundColor(.white)
                .padding(.bottom, 12)

            ZStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(result.archetype.description)
                        .font(.custom("HelveticaNeue", size: 17))
                        .foregroundColor(Color(white: 0.5))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Rectangle()
                        .fill(Color(white: 0.12))
                        .frame(height: 1)
                        .padding(.vertical, 8)

                    HStack(alignment: .bottom, spacing: 6) {
                        Text("\(result.archetype.percentage)%")
                            .font(.custom("HelveticaNeue", size: 32))
                            .foregroundColor(.white)
                        Text("of thinkers\nshare this archetype")
                            .font(.custom("HelveticaNeue", size: 12))
                            .foregroundColor(Color(white: 0.3))
                            .lineSpacing(3)
                    }
                }
                .blur(radius: 8)
                .allowsHitTesting(false)

                VStack(spacing: 14) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(white: 0.45))
                    Text("unlock to see what\nthis means about you")
                        .font(.custom("HelveticaNeue", size: 15))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.top, 16)
            }

            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    // MARK: – Card 5: Pattern ─────────────────────────────────────────────────

    private var patternCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeading("pattern")
                .padding(.top, 72)
                .padding(.bottom, 24)

            ZStack {
                Group {
                    if !debugForcePattern && viewModel.thinkCountForPattern < 5 {
                        earlyPatternView
                    } else if let pattern = viewModel.patternData {
                        fullPatternView(pattern: pattern)
                    } else {
                        earlyPatternView
                    }
                }
                .blur(radius: isPaidTier ? 0 : 8)
                .allowsHitTesting(isPaidTier)

                if !isPaidTier {
                    VStack(spacing: 14) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(white: 0.45))
                        Text("unlock to reveal\nyour pattern identity")
                            .font(.custom("HelveticaNeue", size: 15))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .onAppear {
            // Only refresh if no pattern data exists.
            // Matching the correct guard in PatternView.swift line 43.
            // Without this guard — API fires every time user reaches this card
            // causing pattern identity to regenerate with different results each time.
            if viewModel.thinkCountForPattern >= 5 && viewModel.patternData == nil {
                viewModel.refreshPatternIfNeeded()
            }
        }
    }

    // MARK: – Card 6: History Insight ───────────────────────────────────────

    private var historyInsightCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeading("from your thinks")
                .padding(.horizontal, 28)
                .padding(.top, 72)
                .padding(.bottom, 32)

            if isPaidTier {
                Text(historyPart1)
                    .font(.custom("HelveticaNeue", size: 22))
                    .foregroundColor(.white)
                    .lineSpacing(8)
                    .padding(.horizontal, 28)
            } else {
                ZStack(alignment: .top) {
                    Text(historyPart1)
                        .font(.custom("HelveticaNeue", size: 22))
                        .foregroundColor(.white)
                        .lineSpacing(8)
                        .padding(.horizontal, 28)
                        .blur(radius: 8)
                        .allowsHitTesting(false)

                    VStack(spacing: 14) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(white: 0.45))
                        Text("unlock to see what\nthe brain noticed about you")
                            .font(.custom("HelveticaNeue", size: 15))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.top, 16)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    historyAvailableHeight = geo.size.height - 72 - 16 - 32 - 60
                }
            }
        )
    }

    private var historyInsightCard2: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeading("from your thinks, cont.")
                .padding(.horizontal, 28)
                .padding(.top, 72)
                .padding(.bottom, 32)

            if isPaidTier {
                Text(historyPart2)
                    .font(.custom("HelveticaNeue", size: 22))
                    .foregroundColor(.white)
                    .lineSpacing(8)
                    .padding(.horizontal, 28)
            } else {
                ZStack(alignment: .top) {
                    Text(historyPart2)
                        .font(.custom("HelveticaNeue", size: 22))
                        .foregroundColor(.white)
                        .lineSpacing(8)
                        .padding(.horizontal, 28)
                        .blur(radius: 8)
                        .allowsHitTesting(false)

                    VStack(spacing: 14) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(white: 0.45))
                        Text("unlock to see what\nthe brain noticed about you")
                            .font(.custom("HelveticaNeue", size: 15))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.top, 16)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var earlyPatternView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(contextualPatternObservation)
                .font(.custom("HelveticaNeue", size: 28))
                .foregroundColor(.white)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            Text("your brain is starting\nto map how you think.")
                .font(.custom("HelveticaNeue", size: 16))
                .foregroundColor(Color(white: 0.4))
                .lineSpacing(4)

            Spacer().frame(height: 16)

            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index < viewModel.thinkCountForPattern ? Color.white : Color(white: 0.15))
                        .frame(width: 32, height: 3)
                }
            }

            Text(viewModel.thinkCountForPattern >= 5
                ? "your pattern is being analyzed…"
                : "\(max(0, 5 - viewModel.thinkCountForPattern)) more thinks until your pattern emerges.")
                .font(.custom("HelveticaNeue", size: 12))
                .foregroundColor(Color(white: 0.25))
                .padding(.top, 8)
        }
    }

    private var contextualPatternObservation: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let isNight   = hour >= 21 || hour <= 4
        let isEvening = hour >= 18 && hour < 21
        switch activeMode {
        case .decision:
            return isNight ? "you make decisions\nat night." : isEvening ? "you think when\nthe day winds down." : "you came here\nfor an answer."
        case .direction:
            return isNight ? "you plan your future\nafter midnight." : "you're building\nsomething."
        case .emotional:
            return isNight ? "you process\nin the dark." : "you sit with things\nbefore you speak."
        }
    }

    private func fullPatternView(pattern: PatternData) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(pattern.identity.name)
                .font(.custom("HelveticaNeue", size: 38))
                .foregroundColor(.white)
                .lineSpacing(4)
                .padding(.bottom, 12)

            Text(pattern.identity.description)
                .font(.custom("HelveticaNeue", size: 17))
                .foregroundColor(Color(white: 0.5))
                .lineSpacing(4)
                .padding(.bottom, 28)

            Rectangle()
                .fill(Color(white: 0.12))
                .frame(height: 1)
                .padding(.bottom, 24)

            HStack(alignment: .bottom, spacing: 6) {
                Text("\(pattern.identity.percentage)%")
                    .font(.custom("HelveticaNeue", size: 32))
                    .foregroundColor(.white)
                Text("of thinkers\nshare this")
                    .font(.custom("HelveticaNeue", size: 12))
                    .foregroundColor(Color(white: 0.3))
                    .lineSpacing(3)
                    .padding(.bottom, 3)
            }
            .padding(.bottom, 24)

            Text(pattern.identity.insight)
                .font(.custom("HelveticaNeue", size: 14))
                .foregroundColor(Color(white: 0.35))
                .lineSpacing(5)
                .italic()
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
    }

    private func blurredPatternView(pattern: PatternData) -> some View {
        fullPatternView(pattern: pattern)
            .blur(radius: 8)
            .allowsHitTesting(false)
    }

    // MARK: – Shared components ───────────────────────────────────────────────

    private func cardHeading(_ text: String) -> some View {
        return Text(text.uppercased())
            .font(.custom("HelveticaNeue", size: 13))
            .foregroundColor(Color(white: 0.55))
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func outcomeRow(_ row: OutcomeRow) -> some View {
        HStack(alignment: .top, spacing: 20) {
            // Left: big % + label beneath
            VStack(alignment: .leading, spacing: 4) {
                Text("\(row.percentage)%")
                    .font(.custom("HelveticaNeue", size: 52))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(row.title.prefix(1).uppercased() + row.title.dropFirst())
                    .font(.custom("HelveticaNeue", size: 12))
                    .foregroundColor(Color(white: 0.42))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 100, alignment: .leading)

            // Right: explanation
            Text(row.explanation.prefix(1).uppercased() + row.explanation.dropFirst())
                .font(.custom("HelveticaNeue", size: 13))
                .foregroundColor(Color(white: 0.42))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)
        }
    }

    @ViewBuilder
    private func simpleRow(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Rectangle()
                .fill(Color(white: 0.18))
                .frame(height: 1)
            Text(text)
                .font(.custom("HelveticaNeue", size: 15))
                .foregroundColor(Color(white: 0.65))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
    }

    // MARK: – Progress bar ────────────────────────────────────────────────────

    private func barWidth(_ index: Int, _ total: CGFloat) -> CGFloat {
        if index < currentIndex  { return total }
        if index == currentIndex { return total * CGFloat(progress) }
        return 0
    }

    // MARK: – Timer (Date-based for accuracy at 30 fps) ───────────────────────

    private func startProgress() {
        segElapsed = 0
        segStart   = Date()
        progress   = 0
        scheduleTimer()
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            let total = segElapsed + Date().timeIntervalSince(segStart)
            progress  = min(total / storyDuration, 1.0)
            if progress >= 1.0 { goForward() }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func pauseIfNeeded() {
        guard !isPaused else { return }
        isPaused = true
        timer?.invalidate()
        timer    = nil
        segElapsed += Date().timeIntervalSince(segStart)
    }

    private func resumeIfNeeded() {
        guard isPaused else { return }
        isPaused = false
        segStart = Date()
        scheduleTimer()
    }

    // MARK: – Navigation ──────────────────────────────────────────────────────

    private func goForward() {
        stopTimer(); showTooltip = false; isPaused = false
        if currentIndex < totalCards - 1 {
            currentIndex += 1
            startProgress()
        } else {
            dismiss()
        }
    }

    private func goBack() {
        stopTimer(); showTooltip = false; isPaused = false
        if currentIndex > 0 { currentIndex -= 1 }
        startProgress()
    }
}
