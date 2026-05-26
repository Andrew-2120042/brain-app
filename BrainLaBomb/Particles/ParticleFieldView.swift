import SwiftUI

struct ParticleFieldView: View {
    @ObservedObject var field: ParticleField

    var body: some View {
        Canvas { ctx, size in
            let cx   = Float(size.width)  * 0.5
            let cy   = Float(size.height) * 0.5
            let camZ = field.cameraZ

            for p in field.particles {
                guard p.alpha > 0.004 else { continue }

                // Perspective depth — z ∈ [−140, +140], depth ∈ [120, 400]
                let depth = p.pos.z + camZ
                guard depth > 1 else { continue }

                let sx = CGFloat(cx + p.pos.x * camZ / depth)
                let sy = CGFloat(cy - p.pos.y * camZ / depth)  // flip Y

                // Dim & shrink far particles for strong depth illusion
                let depthNorm  = Double((p.pos.z + 140) / 280)   // 0=near, 1=far
                let depthAlpha = 1.0 - depthNorm * 0.74
                let finalAlpha = Double(p.alpha) * depthAlpha
                guard finalAlpha > 0.005 else { continue }

                // Dot radius scales with perspective: ~2.8 pt near → ~0.9 pt far
                let dotR = CGFloat(1.35 * camZ / depth)
                guard dotR > 0.08 else { continue }

                let rect = CGRect(x: sx - dotR, y: sy - dotR,
                                  width: dotR * 2, height: dotR * 2)
                ctx.fill(Path(ellipseIn: rect),
                         with: .color(.white.opacity(finalAlpha)))
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
