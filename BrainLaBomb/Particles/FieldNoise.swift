import Foundation
import simd

// MARK: - Seeded RNG

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 1 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

// MARK: - Noise & field math

enum FieldNoise {

    /// Fast smooth value noise using trig superposition. Returns ∈ [−1, +1].
    @inline(__always)
    static func smooth(_ x: Float, _ y: Float, _ t: Float) -> Float {
        sin(x * 1.40 + t * 0.71) * cos(y * 1.30 - t * 0.53) * 0.50
      + sin(y * 0.78 + t * 0.61) * cos(x * 0.69 - t * 0.37) * 0.30
      + sin(x * 2.10 + y * 1.73 + t * 0.29)                  * 0.20
    }

    /// 2D curl of smooth noise — divergence-free atmospheric flow.
    /// Returns a 3D force (Z component is gentle independent drift).
    @inline(__always)
    static func curl(_ p: SIMD3<Float>, scale: Float, t: Float) -> SIMD3<Float> {
        let s  = p * scale
        let e: Float = 0.06
        let ie = 1.0 / (2.0 * e)
        let cx = (smooth(s.x, s.y + e, t) - smooth(s.x, s.y - e, t)) *  ie
        let cy = (smooth(s.x + e, s.y, t) - smooth(s.x - e, s.y, t)) * -ie
        let cz =  smooth(s.x * 0.5, s.z,   t + 2.73)                  * 0.22
        return SIMD3(cx, cy, cz)
    }

    // MARK: Brain surface

    /// Signed distance to the brain surface (smooth union of two hemispheres).
    /// +ve = outside, −ve = inside, 0 = on surface. Pixel-space coords.
    @inline(__always)
    static func brainSDF(_ p: SIMD3<Float>) -> Float {
        let r: Float = 78, xo: Float = 34
        let dl = simd_length(p - SIMD3(-xo, 0, 0)) - r
        let dr = simd_length(p - SIMD3( xo, 0, 0)) - r
        return min(dl, dr)
    }

    /// Outward unit surface normal at p (gradient of brainSDF).
    @inline(__always)
    static func brainNormal(_ p: SIMD3<Float>) -> SIMD3<Float> {
        let xo: Float = 34
        let cl = SIMD3<Float>(-xo, 0, 0)
        let cr = SIMD3<Float>( xo, 0, 0)
        let dl = simd_length(p - cl)
        let dr = simd_length(p - cr)
        let c  = dl < dr ? cl : cr
        let d  = p - c
        let l  = simd_length(d)
        return l > 0.0001 ? d / l : SIMD3(0, 1, 0)
    }
}
