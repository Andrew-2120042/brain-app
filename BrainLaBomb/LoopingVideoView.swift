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

        view.playerLayer.player = player
        view.playerLayer.videoGravity = gravity
        player.play()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    class Coordinator {
        var player: AVQueuePlayer?
        var looper: AVPlayerLooper?
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
