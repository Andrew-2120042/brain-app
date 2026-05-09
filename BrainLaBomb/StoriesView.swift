import SwiftUI

struct StoriesView: View {
    let result: DecisionResult
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

    private var activeMode: DecisionMode { debugModeOverride ?? result.mode }

    private let totalCards = 4
    private let storyDuration: TimeInterval = 7.0

    private var tooltipText: String {
        currentIndex == 1
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
                case 1: card2
                case 2: card3
                default: card4
                }
            }
            .id(currentIndex)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading ).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.25), value: currentIndex)

            // ── Tap zones with pause / navigate ──────────────────────────────
            HStack(spacing: 0) {
                tapZone(onShortTap: {
                    if showTooltip { showTooltip = false } else { goBack() }
                })
                tapZone(onShortTap: {
                    if showTooltip { showTooltip = false } else { goForward() }
                })
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
                    Spacer()
                    // Info button (cards 2 & 3)
                    if (currentIndex == 1 || currentIndex == 2) && (activeMode == .decision || activeMode == .direction) {
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
                        Button { onContinueInChat() } label: {
                            Text("continue in chat")
                                .font(.custom("HelveticaNeue", size: 16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white, lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())

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
        let para = "\u{201C}" + result.report.reasoning.joined(separator: " ") + "\u{201D}"
        return Group {
            if reasoningDebug {
                VStack {
                    Spacer()
                    Text(para)
                        .font(.custom("HelveticaNeue", size: 22))
                        .foregroundColor(.white)
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                    Spacer()
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        cardHeading("reasoning")
                            .padding(.top, 72)

                        Spacer().frame(height: 28)

                        Text(para)
                            .font(.custom("HelveticaNeue", size: 22))
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

    private var card4: some View {
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
