import SwiftUI

struct HomeView: View {
    let isProcessing: Bool
    let onTap: () -> Void

    @State private var homeVersion: Int = 0

    private let bgURL  = Bundle.main.url(forResource: "home_bg",  withExtension: "mp4")!
    private let bgURL5 = Bundle.main.url(forResource: "home_bg5", withExtension: "mp4")!

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if homeVersion == 0 {
                LoopingVideoView(url: bgURL).ignoresSafeArea().scaleEffect(1.35)
            } else {
                LoopingVideoView(url: bgURL5).ignoresSafeArea().scaleEffect(1.35)
            }

            version1

            // version toggle (top-right)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { homeVersion = (homeVersion + 1) % 2 }
                    } label: {
                        Text("v\(homeVersion + 1)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(white: 0.35))
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color(white: 0.12).clipShape(Capsule()))
                    }
                    .padding(.top, 62).padding(.trailing, 24)
                }
                Spacer()
            }
        }
    }

    // ── Version 1 ─────────────────────────────────────────────────────────────
    private var version1: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text("Every choice is\na simulation.")
                .font(.custom("HelveticaNeue", size: 48))
                .foregroundColor(.white)
                .lineSpacing(4)
                .padding(.horizontal, 28)

            Spacer()

            if isProcessing {
                ProcessingView()
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 60)
            } else {
                VStack(spacing: 12) {
                    Button(action: onTap) {
                        Text("Think")
                            .font(.custom("HelveticaNeue", size: 17))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Text("what's your situation?")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(white: 0.25))
                        .tracking(2)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 56)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // ── Version 2 ─────────────────────────────────────────────────────────────
    private var version2: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text("Every choice is\na simulation.")
                .font(.custom("HelveticaNeue", size: 48))
                .foregroundColor(.white)
                .lineSpacing(4)
                .padding(.horizontal, 28)

            Spacer().frame(height: 48)

            if isProcessing {
                ProcessingView()
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 60)
            } else {
                Button(action: onTap) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("simulate before you decide.")
                            .font(.custom("HelveticaNeue", size: 16))
                            .foregroundColor(Color(white: 0.40))
                        Rectangle()
                            .fill(Color(white: 0.30))
                            .frame(height: 1)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 28)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: – Processing indicator

struct ProcessingView: View {
    @State private var dotCount = 1
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color(white: 0.30))
                    .frame(width: 5, height: 5)
                    .scaleEffect(dotCount == i + 1 ? 1.4 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: dotCount)
            }
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
                dotCount = dotCount % 3 + 1
            }
        }
        .onDisappear { timer?.invalidate() }
    }
}
