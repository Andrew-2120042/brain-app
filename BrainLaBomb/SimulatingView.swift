import SwiftUI

struct SimulatingView: View {
    private let videoURL = Bundle.main.url(forResource: "cosmos_2032149229", withExtension: "mp4")!

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // ── Label ─────────────────────────────────────────────────────
                Text("SIMULATING")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(white: 0.55))
                    .tracking(4)
                    .padding(.top, 62)
                    .padding(.leading, 24)

                Spacer()

                // ── Sphere animation ──────────────────────────────────────────
                LoopingVideoView(url: videoURL, gravity: .resizeAspect)
                    .frame(width: 320, height: 320)
                    .frame(maxWidth: .infinity)

                Spacer()

                // ── Bottom text ───────────────────────────────────────────────
                Text("Modelling thousands of\npossible outcomes")
                    .font(.custom("HelveticaNeue", size: 30))
                    .foregroundColor(.white)
                    .lineSpacing(4)
                    .padding(.leading, 24)
                    .padding(.bottom, 64)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
