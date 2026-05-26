import Foundation
import SwiftUI
import simd
import QuartzCore

// MARK: - Particle

struct FieldParticle {
    var pos:    SIMD3<Float>   // pixels from screen centre; z ∈ [−140, +140]
    var vel:    SIMD3<Float>   // px / frame
    var phase:  Float          // unique oscillation offset, fixed for particle lifetime
    var alpha:  Float          // current rendered alpha
    var tAlpha: Float          // target alpha
}

// MARK: - Field state

enum FieldState: Equatable {
    case dormant       // Screen 0 — sparse distant field, slow rotation
    case expanding     // Screen 1 — field widens, wave interference
    case signaling     // Screen 2 — flow-line currents emerge
    case conflict      // Screen 3 — dual invisible attractor regions
    case compressing   // Screen 4 — density tightens, inward spiral
    case forming       // Screens 5–6 — brain silhouette emerges from the field
    case living        // Screens 7–8 — brain fully alive, neural surface drift
    case calming       // Screen 9 — motion slows, field stabilises
    case fading        // Screens 10+ — graceful alpha fade
}

// MARK: - Engine

final class ParticleField: ObservableObject {
    static let count = 3000

    // Particle array — written on main thread by tick(), read by Canvas
    var particles: [FieldParticle] = []

    // Projection constants read by ParticleFieldView
    let cameraZ: Float = 260
    let fov:     Float = 400

    private(set) var state: FieldState = .dormant
    private var time: Float = 0

    // ── Blended force parameters ─────────────────────────────────────────────
    // curr values blend toward t* targets each frame (exponential smoothing)

    private var curlScale:   Float = 0.0040
    private var curlAmp:     Float = 0.012
    private var rotSpeed:    Float = 0.0022
    private var waveAmp:     Float = 0
    private var conflictAmp: Float = 0
    private var spiralAmp:   Float = 0
    private var brainAmp:    Float = 0   // blends at slow rate for organic emergence
    private var flowAmp:     Float = 0
    private var drag:        Float = 0.975

    private var tCurlScale:   Float = 0.0040
    private var tCurlAmp:     Float = 0.012
    private var tRotSpeed:    Float = 0.0022
    private var tWaveAmp:     Float = 0
    private var tConflictAmp: Float = 0
    private var tSpiralAmp:   Float = 0
    private var tBrainAmp:    Float = 0
    private var tFlowAmp:     Float = 0
    private var tDrag:        Float = 0.975

    // Fast blend (~2.5 s to 80%) for field dynamics
    private let blendFast: Float = 0.018
    // Slow blend (~8 s to 80%) so brain emerges organically, not via snap
    private let blendBrain: Float = 0.0042

    private var displayLink: CADisplayLink?
    private var proxy: TickProxy?

    // MARK: - Init

    init() {
        buildParticles()
        startDisplayLink()
    }

    // MARK: - Public API

    func setState(_ newState: FieldState) {
        guard newState != state else { return }
        state = newState
        applyTargets(newState)
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    deinit { displayLink?.invalidate() }

    // MARK: - Particle initialisation

    private func buildParticles() {
        var rng = SeededRNG(seed: 0xF13D_2026_CAFE)
        let n = Self.count

        particles = (0..<n).map { i in
            // Unique oscillation phase, evenly spread — never two particles in sync
            let phase = Float(i) / Float(n) * 2 * Float.pi

            // Mix: 2/3 within visible range, 1/3 spread wider so field feels vast
            let wide = i % 3 == 0
            let xRange: ClosedRange<Float> = wide ? -340...340 : -220...220
            let yRange: ClosedRange<Float> = wide ? -570...570 : -390...390
            let x = Float.random(in: xRange, using: &rng)
            let y = Float.random(in: yRange, using: &rng)
            let z = Float.random(in: -140...140, using: &rng)

            return FieldParticle(pos:    SIMD3(x, y, z),
                                 vel:    .zero,
                                 phase:  phase,
                                 alpha:  0,
                                 tAlpha: 0.34)
        }
    }

    // MARK: - State → target parameters

    private func applyTargets(_ s: FieldState) {
        switch s {
        case .dormant:
            tCurlScale = 0.0035; tCurlAmp = 0.011; tRotSpeed = 0.0022
            tWaveAmp = 0;        tConflictAmp = 0;  tSpiralAmp = 0
            tBrainAmp = 0;       tFlowAmp = 0;      tDrag = 0.977
            setAlpha(0.32)

        case .expanding:
            tCurlScale = 0.0045; tCurlAmp = 0.018; tRotSpeed = 0.0012
            tWaveAmp = 0.0058;   tConflictAmp = 0;  tSpiralAmp = 0
            tBrainAmp = 0;       tFlowAmp = 0;      tDrag = 0.974
            setAlpha(0.36)

        case .signaling:
            tCurlScale = 0.0055; tCurlAmp = 0.024; tRotSpeed = 0.0008
            tWaveAmp = 0;        tConflictAmp = 0;  tSpiralAmp = 0
            tBrainAmp = 0;       tFlowAmp = 0;      tDrag = 0.971
            setAlpha(0.40)

        case .conflict:
            tCurlScale = 0.0048; tCurlAmp = 0.016; tRotSpeed = 0.0014
            tWaveAmp = 0;        tConflictAmp = 0.017; tSpiralAmp = 0
            tBrainAmp = 0;       tFlowAmp = 0;      tDrag = 0.974
            setAlpha(0.42)

        case .compressing:
            tCurlScale = 0.0060; tCurlAmp = 0.013; tRotSpeed = 0.0030
            tWaveAmp = 0;        tConflictAmp = 0;  tSpiralAmp = 0.013
            tBrainAmp = 0;       tFlowAmp = 0;      tDrag = 0.972
            setAlpha(0.44)

        case .forming:
            tCurlScale = 0.0048; tCurlAmp = 0.014; tRotSpeed = 0.0010
            tWaveAmp = 0;        tConflictAmp = 0;  tSpiralAmp = 0
            tBrainAmp = 0.00055; tFlowAmp = 0;      tDrag = 0.975
            setAlpha(0.50)

        case .living:
            tCurlScale = 0.0040; tCurlAmp = 0.010; tRotSpeed = 0.0005
            tWaveAmp = 0;        tConflictAmp = 0;  tSpiralAmp = 0
            tBrainAmp = 0.00080; tFlowAmp = 0.00028; tDrag = 0.977
            setAlpha(0.58)

        case .calming:
            tCurlScale = 0.0032; tCurlAmp = 0.007; tRotSpeed = 0.0003
            tWaveAmp = 0;        tConflictAmp = 0;  tSpiralAmp = 0
            tBrainAmp = 0.00060; tFlowAmp = 0.00016; tDrag = 0.979
            setAlpha(0.46)

        case .fading:
            tCurlScale = 0.0022; tCurlAmp = 0.004; tRotSpeed = 0
            tWaveAmp = 0;        tConflictAmp = 0;  tSpiralAmp = 0
            tBrainAmp = 0;       tFlowAmp = 0;      tDrag = 0.981
            setAlpha(0)
        }
    }

    private func setAlpha(_ a: Float) {
        for i in 0..<particles.count { particles[i].tAlpha = a }
    }

    // MARK: - Display link

    private func startDisplayLink() {
        let p = TickProxy { [weak self] in self?.tick() }
        proxy = p
        let link = CADisplayLink(target: p, selector: #selector(TickProxy.step(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    // MARK: - Physics tick (main thread, ~60 fps)

    func tick() {
        time += 1.0 / 60.0
        let t = time

        // ── Blend force parameters toward targets ──────────────────────────
        let bf = blendFast, bb = blendBrain
        curlScale   += (tCurlScale   - curlScale)   * bf
        curlAmp     += (tCurlAmp     - curlAmp)     * bf
        rotSpeed    += (tRotSpeed    - rotSpeed)     * bf
        waveAmp     += (tWaveAmp     - waveAmp)      * bf
        conflictAmp += (tConflictAmp - conflictAmp)  * bf
        spiralAmp   += (tSpiralAmp   - spiralAmp)    * bf
        flowAmp     += (tFlowAmp     - flowAmp)      * bf
        drag        += (tDrag        - drag)         * bf
        brainAmp    += (tBrainAmp    - brainAmp)     * bb  // organic, slow

        let cs = curlScale, ca = curlAmp
        let rs = rotSpeed
        let wa = waveAmp
        let coa = conflictAmp, sa = spiralAmp
        let ba = brainAmp, fa = flowAmp
        let dr = drag
        let maxSpd: Float = 1.5

        for i in 0..<particles.count {
            let p  = particles[i].pos
            let ph = particles[i].phase

            // Depth-based speed scaling — near particles move noticeably faster
            let depthNorm = (p.z + 140) / 280              // 0 = near, 1 = far
            let spd = 1.0 - depthNorm * 0.50               // 1.0 near → 0.5 far

            // ── 1. Curl noise — always-on atmospheric drift ────────────────
            let curlForce: SIMD3<Float> = FieldNoise.curl(p, scale: cs, t: t)
            var force: SIMD3<Float> = curlForce * (ca * spd)

            // ── 2. Global slow rotation (XZ plane orbit) ───────────────────
            if rs > 0.00004 {
                force.x -= p.z * rs * spd
                force.z += p.x * rs * spd
            }

            // ── 3. Micro-motion — unique per particle, never fully stops ───
            // Low-amplitude continuous oscillation keeps the field breathing
            force.x += sin(t * 0.88 + ph)       * 0.0024
            force.y += cos(t * 1.07 + ph)       * 0.0024
            force.z += sin(t * 0.63 + ph * 1.4) * 0.0015

            // ── 4. Wave expansion — field stretches and breathes ───────────
            if wa > 0.0001 {
                force.x += sin(p.y * 0.009 + t * 0.38) * (wa * spd)
                force.y += cos(p.x * 0.007 - t * 0.28) * (wa * 0.35 * spd)
            }

            // ── 5. Dual invisible attractors — psychological pull ───────────
            if coa > 0.0001 {
                let lc = SIMD3<Float>(-152, 18, 0)
                let rc = SIMD3<Float>( 152, -18, 0)
                let tl = lc - p;  let dl = max(simd_length(tl), 1)
                let tr2 = rc - p; let dr2 = max(simd_length(tr2), 1)
                let wl: Float = max(0, 1.0 - dl / 290) * coa
                let wr: Float = max(0, 1.0 - dr2 / 290) * coa
                let dirL: SIMD3<Float> = tl / dl
                let dirR: SIMD3<Float> = tr2 / dr2
                let aL: SIMD3<Float> = dirL * wl
                let aR: SIMD3<Float> = dirR * wr
                force += aL + aR
            }

            // ── 6. Inward spiral — field compresses and orbits ─────────────
            if sa > 0.0001 {
                let dist = max(simd_length(p), 1)
                force -= (p / dist) * (sa * 0.45 * spd)   // toward centre
                // Tangential (rotation in XZ)
                let tangent = simd_normalize(SIMD3(-p.z, 0, p.x) + SIMD3(0.001, 0, 0))
                force += tangent * (sa * 0.55 * spd)
            }

            // ── 7. Brain surface attraction — formation emerges ─────────────
            if ba > 0.0001 {
                let sdf    = FieldNoise.brainSDF(p)
                let cSDF   = simd_clamp(sdf, -88, 88)
                let normal = FieldNoise.brainNormal(p)
                // Pull toward surface (sdf=0): outside → inward, inside → outward
                force -= normal * (cSDF * ba)

                // ── 8. Neural surface flow — brain feels alive ──────────────
                if fa > 0.00004 {
                    let up      = SIMD3<Float>(0, 1, 0)
                    let tangent = up - simd_dot(up, normal) * normal
                    let tLen    = simd_length(tangent)
                    if tLen > 0.05 {
                        let proximity = max(0, 1.0 - abs(sdf) / 55.0)
                        force += (tangent / tLen) * (fa * proximity)
                    }
                }
            }

            // ── 9. Soft boundary — field is vast but not infinite ──────────
            // Gentle restore force when particles drift too far off-screen
            let bx: Float = 345, by: Float = 595, bz: Float = 158
            if p.x >  bx { force.x -= (p.x -  bx) * 0.0022 }
            if p.x < -bx { force.x -= (p.x + bx) * 0.0022 }
            if p.y >  by { force.y -= (p.y -  by) * 0.0022 }
            if p.y < -by { force.y -= (p.y + by) * 0.0022 }
            if p.z >  bz { force.z -= (p.z -  bz) * 0.0022 }
            if p.z < -bz { force.z -= (p.z + bz) * 0.0022 }

            // ── Integrate — linear drag only, no spring ────────────────────
            var vel = particles[i].vel * dr + force
            let speed = simd_length(vel)
            if speed > maxSpd { vel *= maxSpd / speed }

            particles[i].vel  = vel
            particles[i].pos += vel
            particles[i].alpha += (particles[i].tAlpha - particles[i].alpha) * 0.028
        }

        objectWillChange.send()
    }
}

// MARK: - CADisplayLink proxy (prevents retain cycle)

private final class TickProxy: NSObject {
    let action: () -> Void
    init(_ action: @escaping () -> Void) { self.action = action }
    @objc func step(_ link: CADisplayLink) { action() }
}
