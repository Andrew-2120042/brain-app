import SwiftUI

struct CardBackView: View {
    let result: DecisionResult
    @State private var showStories = false

    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 0) {

                // ── Why ──────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 10) {
                    Text("Why")
                        .font(.custom("Poppins-Regular", size: 24))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(result.why, id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(Color(white: 0.5))
                                Text(point)
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(Color(white: 0.5))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 22)

                Spacer().frame(height: 28)

                // ── Trade offs ───────────────────────────────────────
                VStack(alignment: .leading, spacing: 10) {
                    Text("Trade offs")
                        .font(.custom("Poppins-Regular", size: 24))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(result.tradeoffs, id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(Color(white: 0.5))
                                Text(point)
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(Color(white: 0.5))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)

                Spacer()

                // ── View full report button ───────────────────────────
                Button { showStories = true } label: {
                    HStack {
                        Text("view full report")
                            .font(.custom("Poppins-Regular", size: 15))
                            .foregroundColor(.black)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 20)
                .fullScreenCover(isPresented: $showStories) {
                    StoriesView(result: result)
                }
            }
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
