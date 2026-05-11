import SwiftUI
import CoreMotion

private let layoutLabels = ["A", "B", "C", "D", "E"]

struct DecisionCardView: View {
    let result:                  DecisionResult
    let originalQuestion:        String
    let onReset:                 () -> Void
    var allowSwipeDismiss:       Bool = true
    @ObservedObject var viewModel: AppViewModel
    let thinkID:                 UUID
    let existingChatMessages:    [ChatBubble]
    let onChatMessagesUpdated:   ([ChatBubble]) -> Void

    @State private var layoutIndex: Int     = 0
    @State private var cardScale: CGFloat   = 0.92
    @State private var cardAngle: Double    = 0
    @State private var tiltX:     Double    = 0
    @State private var tiltY:     Double    = 0
    @State private var dragBase:  Double    = 0
    @State private var dragStarted          = false

    // Arrival animation
    @State private var cardOffset: CGFloat  = UIScreen.main.bounds.height + 200
    @State private var cardOpacity: Double  = 0

    private static let motion = CMMotionManager()

    private var frontVisible: Bool { cos(cardAngle * .pi / 180) >= 0 }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image("float_bg")
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width * 1.1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .colorMultiply(Color(white: 0.45))

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button(action: dismissCard) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Back")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(Color(white: 0.45))
                    }
                    Spacer()
                }
                .padding(.leading, 44).padding(.trailing, 24).padding(.top, 14)

                Text("RECOMMENDATION")
                    .font(.custom("HelveticaNeue", size: 28))
                    .foregroundColor(.white)
                    .padding(.leading, 44).padding(.trailing, 24).padding(.top, 16)
                Spacer()
                floatGlow
                    .padding(.horizontal, 52)
                    .frame(maxWidth: .infinity)
                    .offset(y: cardOffset)
                    .opacity(cardOpacity)
                Spacer()
                Text("RESULTS AFTER SIMULATING\nTHOUSANDS OF SCENARIOS")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(1).lineSpacing(3)
                    .padding(.leading, 44).padding(.trailing, 24).padding(.bottom, 12)
                debugBar.padding(.bottom, 48)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            layoutIndex = Int.random(in: 0...4)
            withAnimation(.spring(response: 1.0, dampingFraction: 0.85)) {
                cardOffset  = 0
                cardOpacity = 1
                cardScale   = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            startGyro()
        }
        .onDisappear { Self.motion.stopDeviceMotionUpdates() }
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { v in
                    guard allowSwipeDismiss else { return }
                    if v.translation.height > 100 && abs(v.translation.width) < 80 {
                        dismissCard()
                    }
                }
        )
    }

    // ── Dismiss ───────────────────────────────────────────────────────────────
    private func dismissCard() {
        onReset()
    }

    // ── Gyroscope ─────────────────────────────────────────────────────────────
    private func startGyro() {
        guard Self.motion.isDeviceMotionAvailable else { return }
        Self.motion.deviceMotionUpdateInterval = 1.0 / 60.0
        Self.motion.startDeviceMotionUpdates(to: .main) { data, _ in
            guard let data = data, !dragStarted else { return }
            let y = data.gravity.x * -28
            let x = (data.gravity.y + 0.6) * 28
            withAnimation(.easeOut(duration: 0.1)) {
                tiltY = max(-20, min(20, y))
                tiltX = max(-20, min(20, x))
            }
        }
    }

    // ── Drag-to-rotate + tap-to-flip gesture ─────────────────────────────────
    private var cardGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                if !dragStarted {
                    dragStarted = true
                    dragBase = cardAngle
                }
                cardAngle = dragBase + Double(v.translation.width) * 0.55
                withAnimation(.interactiveSpring()) {
                    tiltX = max(-18, min(18, Double(-v.translation.height / 5)))
                }
            }
            .onEnded { v in
                let wasDrag = abs(v.translation.width) > 8
                dragStarted = false
                if wasDrag {
                    let velocity = Double(v.predictedEndTranslation.width - v.translation.width)
                    let snapped  = (cardAngle / 180).rounded() * 180
                    let raw      = abs(velocity) > 300
                        ? (velocity > 0 ? snapped + 180 : snapped - 180)
                        : snapped
                    // Clamp to exactly one flip from where the drag started
                    let target = dragBase + max(-180.0, min(180.0, raw - dragBase))
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.68)) {
                        cardAngle = target
                        tiltX = 0
                    }
                } else {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.68)) { tiltX = 0 }
                    flipCard()
                }
            }
    }

    // ── Card ──────────────────────────────────────────────────────────────────
    private var floatGlow: some View {
        ZStack {
            CardBackView(
                result: result,
                originalQuestion: originalQuestion,
                viewModel: viewModel,
                thinkID: thinkID,
                existingChatMessages: existingChatMessages,
                onChatMessagesUpdated: onChatMessagesUpdated,
                onNewThink: onReset
            )
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5))
                .rotation3DEffect(.degrees(cardAngle + 180), axis: (0, 1, 0), perspective: 1.1)
                .opacity(frontVisible ? 0 : 1)

            DecisionCard(result: result, layoutIndex: layoutIndex)
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5))
                .rotation3DEffect(.degrees(cardAngle), axis: (0, 1, 0), perspective: 1.1)
                .opacity(frontVisible ? 1 : 0)
        }
        .aspectRatio(0.68, contentMode: .fit)
        .scaleEffect(cardScale * 0.88)
        .rotation3DEffect(.degrees(tiltX), axis: (1, 0, 0), perspective: 0.6)
        .rotation3DEffect(.degrees(tiltY), axis: (0, 1, 0), perspective: 0.6)
        .gesture(cardGesture)
        .shadow(color: Color.white.opacity(0.06), radius: 24, x: 0, y: 0)
    }

    // ── Flip (tap) ────────────────────────────────────────────────────────────
    private func flipCard() {
        withAnimation(.easeInOut(duration: 0.44)) { cardAngle += 180 }
    }

    // ── Debug bar ─────────────────────────────────────────────────────────────
    private var debugBar: some View {
        HStack(spacing: 0) {
            Button { layoutIndex = (layoutIndex - 1 + 5) % 5; cardAngle = 0 } label: {
                Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(white: 0.6)).padding(.horizontal, 14).padding(.vertical, 8)
            }
            Text("Layout \(layoutLabels[layoutIndex])")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(Color(white: 0.6)).frame(width: 70, alignment: .center)
            Button { layoutIndex = (layoutIndex + 1) % 5; cardAngle = 0 } label: {
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(white: 0.6)).padding(.horizontal, 14).padding(.vertical, 8)
            }
        }
        .background(Color(white: 0.18).clipShape(Capsule()))
        .frame(maxWidth: .infinity)
    }
}
