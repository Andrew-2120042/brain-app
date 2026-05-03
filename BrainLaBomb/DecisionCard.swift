import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

private extension Font {
    static func verdict(_ size: CGFloat) -> Font { .custom("Poppins-Regular", size: size) }
    static func pct(_ size: CGFloat) -> Font     { .custom("Poppins-Regular", size: size) }
    static var label: Font                       { .custom("Poppins-Regular", size: 12) }
}

private let pctGray   = Color(white: 0.45)
private let labelGray = Color(white: 0.38)

private func videoURL(_ name: String) -> URL {
    Bundle.main.url(forResource: name, withExtension: "mp4")!
}

// Per-layout video assignments
private let videoA = videoURL("cosmos_833015861")
private let videoB = videoURL("cosmos_343223263")
private let videoC = videoURL("cosmos_962608114")
private let videoD = videoURL("cosmos_32819741")
private let videoE = videoURL("cosmos_901376308")

private struct VideoBlock: View {
    let url: URL
    var body: some View {
        LoopingVideoView(url: url)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout A — large video (padded, centred), compact text strip at bottom
// ─────────────────────────────────────────────────────────────────────────────
struct CardLayoutA: View {
    let result: DecisionResult
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Big video with gaps on all sides so it sits centred inside the card
                VideoBlock(url: videoA)
                    .frame(height: geo.size.height * 0.74)
                    .padding(.horizontal, 10)
                    .padding(.top, 10)

                // Compact text strip — left-aligned, bottom of card
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.verdict.lowercased())
                        .font(.verdict(21))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    Text("\(result.confidence)% confidence from simulation")
                        .font(.label)
                        .foregroundColor(labelGray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout B — video top (~40 %), verdict, giant %, label
// ─────────────────────────────────────────────────────────────────────────────
struct CardLayoutB: View {
    let result: DecisionResult
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                VideoBlock(url: videoB)
                    .frame(height: geo.size.height * 0.40)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)

                VStack(alignment: .leading, spacing: 0) {
                    Text(result.verdict.lowercased())
                        .font(.verdict(26))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .minimumScaleFactor(0.75)
                        .padding(.bottom, 8)

                    Spacer()

                    Text("\(result.confidence)%")
                        .font(.pct(90))
                        .foregroundColor(pctGray)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)

                    Text("confidence from simulation")
                        .font(.label)
                        .foregroundColor(labelGray)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout C — verdict top, video middle, giant % + label at bottom
// ─────────────────────────────────────────────────────────────────────────────
struct CardLayoutC: View {
    let result: DecisionResult
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 0) {
                Text(result.verdict.lowercased())
                    .font(.verdict(26))
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    .frame(height: geo.size.height * 0.22, alignment: .bottom)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VideoBlock(url: videoC)
                    .frame(height: geo.size.height * 0.40)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(result.confidence)%")
                        .font(.pct(80))
                        .foregroundColor(pctGray)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)

                    Text("confidence from simulation")
                        .font(.label)
                        .foregroundColor(labelGray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout D — text + % left, tall video strip right (with gap from all edges)
// ─────────────────────────────────────────────────────────────────────────────
struct CardLayoutD: View {
    let result: DecisionResult
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(result.verdict.lowercased())
                        .font(.verdict(24))
                        .foregroundColor(.white)
                        .lineLimit(4)
                        .minimumScaleFactor(0.7)

                    Spacer()

                    Text("\(result.confidence)%")
                        .font(.pct(82))
                        .foregroundColor(pctGray)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)

                    Text("confidence from simulation")
                        .font(.label)
                        .foregroundColor(labelGray)
                        .padding(.top, 4)
                }
                .padding(14)
                .frame(width: geo.size.width * 0.55)
                .frame(maxHeight: .infinity, alignment: .topLeading)

                // Video — padding before frame so gaps genuinely inset the video
                VideoBlock(url: videoD)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    .padding(.leading, 4)
                    .padding(.trailing, 12)
                    .frame(width: geo.size.width * 0.45)
                    .frame(maxHeight: .infinity)
            }
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout E — video top (~44 %), verdict + giant % + label
// ─────────────────────────────────────────────────────────────────────────────
struct CardLayoutE: View {
    let result: DecisionResult
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                VideoBlock(url: videoE)
                    .frame(height: geo.size.height * 0.44)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)

                VStack(alignment: .leading, spacing: 0) {
                    Text(result.verdict.lowercased())
                        .font(.verdict(26))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .minimumScaleFactor(0.75)
                        .padding(.bottom, 6)

                    Spacer()

                    Text("\(result.confidence)%")
                        .font(.pct(86))
                        .foregroundColor(pctGray)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)

                    Text("confidence from simulation")
                        .font(.label)
                        .foregroundColor(labelGray)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// DecisionCard — picks one of the 5 layouts
// ─────────────────────────────────────────────────────────────────────────────
struct DecisionCard: View {
    let result:      DecisionResult
    let layoutIndex: Int

    var body: some View {
        Group {
            switch layoutIndex {
            case 0:  CardLayoutA(result: result)
            case 1:  CardLayoutB(result: result)
            case 2:  CardLayoutC(result: result)
            case 3:  CardLayoutD(result: result)
            default: CardLayoutE(result: result)
            }
        }
    }
}
