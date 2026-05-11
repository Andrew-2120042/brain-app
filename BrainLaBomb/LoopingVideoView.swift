import SwiftUI
import AVKit

struct LoopingVideoView: UIViewRepresentable {
    let url: URL
    var gravity: AVLayerVideoGravity = .resizeAspectFill

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = PlayerView()
        view.backgroundColor = .black

        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        context.coordinator.looper = AVPlayerLooper(player: player, templateItem: item)
        context.coordinator.player = player
        context.coordinator.startObserving()

        view.playerLayer.player = player
        view.playerLayer.videoGravity = gravity
        player.play()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    class Coordinator {
        var player: AVQueuePlayer?
        var looper: AVPlayerLooper?
        private var observers: [NSObjectProtocol] = []

        func startObserving() {
            let nc = NotificationCenter.default

            observers.append(nc.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil, queue: .main) { [weak self] _ in
                    self?.player?.play()
            })

            observers.append(nc.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: nil, queue: .main) { [weak self] note in
                    guard
                        let info = note.userInfo,
                        let raw  = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                        let type = AVAudioSession.InterruptionType(rawValue: raw),
                        type == .ended
                    else { return }
                    self?.player?.play()
            })

            observers.append(nc.addObserver(
                forName: AVPlayerItem.playbackStalledNotification,
                object: nil, queue: .main) { [weak self] _ in
                    self?.player?.play()
            })
        }

        deinit {
            observers.forEach { NotificationCenter.default.removeObserver($0) }
        }
    }
}

private final class PlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
