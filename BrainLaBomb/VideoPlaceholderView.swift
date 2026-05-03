import SwiftUI

// White block with crossed lines — placeholder for looping video.
// Line weight scales with the block size so it looks right in every layout.
struct VideoPlaceholderView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white
                Canvas { ctx, size in
                    let lw   = max(5, min(size.width, size.height) * 0.048)
                    let inX  = size.width  * 0.13
                    let inY  = size.height * 0.13

                    var d1 = Path()
                    d1.move(to:    .init(x: inX,              y: inY))
                    d1.addLine(to: .init(x: size.width - inX, y: size.height - inY))

                    var d2 = Path()
                    d2.move(to:    .init(x: size.width - inX, y: inY))
                    d2.addLine(to: .init(x: inX,              y: size.height - inY))

                    let style = StrokeStyle(lineWidth: lw, lineCap: .round)
                    ctx.stroke(d1, with: .color(.black.opacity(0.78)), style: style)
                    ctx.stroke(d2, with: .color(.black.opacity(0.78)), style: style)
                }
            }
        }
    }
}
