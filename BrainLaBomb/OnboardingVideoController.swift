import AVFoundation
import SwiftUI

// MARK: - JSON model

struct VideoSegment: Decodable {
    let type: String       // "alive" | "transition"
    let startMs: Int
    let endMs: Int
    let shapeTitle: String
}

// MARK: - Controller

final class OnboardingVideoController: ObservableObject {
    let player: AVPlayer

    private var segments: [VideoSegment] = []
    private var currentAliveIdx: Int = 0
    private var isTransitioning = false
    private var loopObserver: Any?
    private var transitionObserver: Any?

    init() {
        guard let url = Bundle.main.url(forResource: "onboarding_master_timeline", withExtension: "mp4") else {
            fatalError("onboarding_master_timeline.mp4 not found in bundle")
        }
        player = AVPlayer(url: url)
        player.isMuted = true
        player.automaticallyWaitsToMinimizeStalling = false
        player.actionAtItemEnd = .none
        loadSegments()
    }

    private func loadSegments() {
        guard let url = Bundle.main.url(forResource: "onboarding_timeline", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let parsed = try? JSONDecoder().decode([VideoSegment].self, from: data)
        else { return }
        segments = parsed
    }

    // Call once when onboarding appears — starts looping the first alive section.
    func start() {
        guard let idx = segments.firstIndex(where: { $0.type == "alive" }) else { return }
        loopAlive(at: idx)
    }

    // Call when the user taps Next on the current screen.
    // Calls `onScreenAdvance` immediately so UI content switches right away,
    // plays the video transition behind the new content, then loops the next alive section.
    // If no transition exists in the JSON, `onScreenAdvance` still fires immediately.
    func playNextTransition(onScreenAdvance: @escaping () -> Void) {
        guard !isTransitioning else { return }

        let transIdx     = currentAliveIdx + 1
        let nextAliveIdx = transIdx + 1

        guard transIdx < segments.count,
              segments[transIdx].type == "transition",
              nextAliveIdx < segments.count,
              segments[nextAliveIdx].type == "alive"
        else {
            onScreenAdvance()
            return
        }

        isTransitioning = true
        removeLoopObserver()

        // Advance screen content immediately — video transition plays behind it
        onScreenAdvance()

        let transSeg  = segments[transIdx]
        let startTime = cmTime(ms: transSeg.startMs)
        let endTime   = cmTime(ms: transSeg.endMs)

        player.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero)
        player.play()

        transitionObserver = player.addBoundaryTimeObserver(
            forTimes: [NSValue(time: endTime)],
            queue: .main
        ) { [weak self] in
            guard let self = self else { return }
            self.removeTransitionObserver()
            self.isTransitioning = false
            self.loopAlive(at: nextAliveIdx)
        }
    }

    // MARK: - Private

    private func loopAlive(at idx: Int) {
        guard idx < segments.count else { return }
        removeLoopObserver()
        currentAliveIdx = idx

        let seg       = segments[idx]
        let startTime = cmTime(ms: seg.startMs)
        let endTime   = cmTime(ms: seg.endMs)

        player.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero)
        player.play()

        loopObserver = player.addBoundaryTimeObserver(
            forTimes: [NSValue(time: endTime)],
            queue: .main
        ) { [weak self] in
            guard let self = self else { return }
            self.player.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }
    }

    private func cmTime(ms: Int) -> CMTime {
        CMTime(value: CMTimeValue(ms), timescale: 1000)
    }

    private func removeLoopObserver() {
        if let obs = loopObserver { player.removeTimeObserver(obs); loopObserver = nil }
    }

    private func removeTransitionObserver() {
        if let obs = transitionObserver { player.removeTimeObserver(obs); transitionObserver = nil }
    }

    deinit {
        removeLoopObserver()
        removeTransitionObserver()
    }
}

// MARK: - Video player view

struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> OnboardingPlayerHostView {
        let view = OnboardingPlayerHostView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: OnboardingPlayerHostView, context: Context) {}
}

final class OnboardingPlayerHostView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
