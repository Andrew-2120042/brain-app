import SwiftUI

struct StoriesView: View {
    let result: DecisionResult

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

    private let totalCards = 5
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
                case 3: card4
                default: card5
                }
            }
            .id(currentIndex)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading ).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.25), value: currentIndex)

            // ── Tap zones with pause / navigate (cards 0–3 only) ─────────────
            if currentIndex < totalCards - 1 {
                HStack(spacing: 0) {
                    tapZone(onShortTap: {
                        if showTooltip { showTooltip = false } else { goBack() }
                    })
                    tapZone(onShortTap: {
                        if showTooltip { showTooltip = false } else { goForward() }
                    })
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
                    Spacer()
                    // Info button (cards 2 & 3)
                    if currentIndex == 1 || currentIndex == 2 {
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
                    Spacer()
                }
                .padding(.leading, 20)
                .padding(.bottom, 36)
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

    // MARK: – Card 2: What this looks like / What goes wrong ──────────────────

    private var card2: some View {
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
    }

    // MARK: – Card 3: The other X% ────────────────────────────────────────────

    private var card3: some View {
        let rem = 100 - result.confidence
        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                cardHeading("the other \(rem)%")
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
    }

    // MARK: – Card 4: Pattern ─────────────────────────────────────────────────

    private var card4: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeading("pattern")
                .padding(.top, 72)

            Spacer()

            VStack(alignment: .leading, spacing: 18) {
                Text("First time thinking\nabout \(result.report.topic).")
                    .font(.custom("HelveticaNeue", size: 22))
                    .foregroundColor(.white)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Your brain is starting\nto learn you.")
                    .font(.custom("HelveticaNeue", size: 22))
                    .foregroundColor(Color(white: 0.38))
                    .lineSpacing(4)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: – Card 5: Done ────────────────────────────────────────────────────

    private var card5: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 10) {
                Text("your brain has thought\nthis through.")
                    .font(.custom("HelveticaNeue", size: 22))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("back whenever you need to think.")
                    .font(.custom("HelveticaNeue", size: 15))
                    .foregroundColor(Color(white: 0.38))
                    .multilineTextAlignment(.center)
            }

            Spacer().frame(height: 44)

            Button { dismiss() } label: {
                Text("back to chat")
                    .font(.custom("HelveticaNeue", size: 16))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Text("this think has been saved — there are five cards")
                .font(.custom("HelveticaNeue", size: 11))
                .foregroundColor(Color(white: 0.28))
                .multilineTextAlignment(.center)
                .padding(.top, 12)

            Spacer()
        }
        .padding(.horizontal, 28)
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
            withAnimation { currentIndex += 1 }
            startProgress()
        }
    }

    private func goBack() {
        stopTimer(); showTooltip = false; isPaused = false
        if currentIndex > 0 { withAnimation { currentIndex -= 1 } }
        startProgress()
    }
}
