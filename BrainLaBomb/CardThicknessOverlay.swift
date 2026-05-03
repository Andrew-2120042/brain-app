import UIKit
import QuartzCore
import SwiftUI

// UIViewRepresentable wrapper — call with the same cardAngle as the SwiftUI card faces.
// Uses CATransformLayer so left/right edge panels genuinely exist in 3D space.
struct CardThicknessOverlay: UIViewRepresentable {
    let angle: Double   // degrees, same as cardAngle

    func makeUIView(context: Context) -> ThicknessUIView {
        let v = ThicknessUIView()
        v.backgroundColor = .clear
        v.isUserInteractionEnabled = false
        return v
    }

    func updateUIView(_ view: ThicknessUIView, context: Context) {
        view.setAngle(CGFloat(angle))
    }
}

// MARK: – UIView

final class ThicknessUIView: UIView {

    private let transformLayer = CATransformLayer()
    private let leftEdge       = CAGradientLayer()
    private let rightEdge      = CAGradientLayer()
    private let thickness: CGFloat = 22

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        leftEdge.colors  = [
            UIColor(white: 0.30, alpha: 1).cgColor,
            UIColor(white: 0.12, alpha: 1).cgColor
        ]
        leftEdge.startPoint  = CGPoint(x: 0, y: 0.5)
        leftEdge.endPoint    = CGPoint(x: 1, y: 0.5)

        rightEdge.colors = [
            UIColor(white: 0.12, alpha: 1).cgColor,
            UIColor(white: 0.28, alpha: 1).cgColor
        ]
        rightEdge.startPoint = CGPoint(x: 0, y: 0.5)
        rightEdge.endPoint   = CGPoint(x: 1, y: 0.5)

        transformLayer.addSublayer(leftEdge)
        transformLayer.addSublayer(rightEdge)
        layer.addSublayer(transformLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width
        let h = bounds.height
        let t = thickness

        transformLayer.frame = bounds

        // ── Left edge ─────────────────────────────────────────────────────────
        // Pivot at the edge's RIGHT side (touching card's left face boundary).
        // anchorPoint (1, 0.5) = right-centre of the panel.
        // position at (0, h/2) in the transformLayer's coordinate space.
        // Then rotate +90° around Y → panel folds backward perpendicular to face.
        leftEdge.bounds       = CGRect(x: 0, y: 0, width: t, height: h)
        leftEdge.anchorPoint  = CGPoint(x: 1.0, y: 0.5)
        leftEdge.position     = CGPoint(x: 0, y: h / 2)
        leftEdge.transform    = CATransform3DRotate(CATransform3DIdentity, .pi / 2, 0, 1, 0)

        // ── Right edge ────────────────────────────────────────────────────────
        // Pivot at LEFT side of panel (touching card's right face boundary).
        rightEdge.bounds      = CGRect(x: 0, y: 0, width: t, height: h)
        rightEdge.anchorPoint = CGPoint(x: 0.0, y: 0.5)
        rightEdge.position    = CGPoint(x: w, y: h / 2)
        rightEdge.transform   = CATransform3DRotate(CATransform3DIdentity, -.pi / 2, 0, 1, 0)

        setAngle(currentAngle)
    }

    private var currentAngle: CGFloat = 0

    func setAngle(_ degrees: CGFloat) {
        currentAngle = degrees
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let w    = bounds.width
        let h    = bounds.height
        // Match SwiftUI rotation3DEffect perspective: 1.1 on this card size.
        // perspective = 1.1 → m34 ≈ -1.1 / max(w,h)
        let maxD = max(w, h)
        var t    = CATransform3DIdentity
        t.m34    = -1.1 / (maxD > 0 ? maxD : 400)
        t        = CATransform3DRotate(t, degrees * .pi / 180, 0, 1, 0)
        transformLayer.transform = t

        CATransaction.commit()
    }
}
