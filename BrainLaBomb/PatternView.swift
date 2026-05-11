import SwiftUI

struct PatternView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A").ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "#666666"))
                            .frame(width: 34, height: 34)
                            .background(Color(white: 0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 4)

                if viewModel.thinkCountForPattern < 5 {
                    emptyStateView
                } else if let pattern = viewModel.patternData {
                    patternRevealView(pattern: pattern)
                } else {
                    analyzingView
                }
            }
        }
        .onAppear {
            #if DEBUG
            if Constants.useMockData && viewModel.patternData == nil {
                viewModel.injectMockPatternData()
            }
            #endif
            if viewModel.thinkCountForPattern >= 5 && viewModel.patternData == nil {
                viewModel.refreshPatternIfNeeded()
            }
        }
    }

    // MARK: - Empty state

    private var emptyStateView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text("your brain is still\nlearning you.")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("\(max(0, 5 - viewModel.thinkCountForPattern)) more thinks until\npatterns start appearing.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(white: 0.35))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)

            Spacer()

            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(index < viewModel.thinkCountForPattern ? Color.white : Color(white: 0.2))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 60)
        }
    }

    // MARK: - Analyzing state

    private var analyzingView: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("finding your pattern...")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Color(white: 0.4))
            Spacer()
        }
    }

    // MARK: - Pattern reveal

    private func patternRevealView(pattern: PatternData) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text("YOUR PATTERN")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(white: 0.3))
                    .tracking(2)
                    .padding(.horizontal, 28)
                    .padding(.top, 8)
                    .padding(.bottom, 40)

                VStack(alignment: .leading, spacing: 0) {
                    Text(pattern.identity.name)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                        .padding(.bottom, 12)

                    Text(pattern.identity.description)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(Color(white: 0.5))
                        .lineSpacing(4)
                        .padding(.bottom, 32)

                    Rectangle()
                        .fill(Color(white: 0.12))
                        .frame(height: 1)
                        .padding(.bottom, 28)

                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(pattern.identity.percentage)%")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)

                        Text("of thinkers\nshare this pattern")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(white: 0.35))
                            .lineSpacing(3)
                            .padding(.bottom, 4)
                    }
                    .padding(.bottom, 28)

                    Text(pattern.identity.insight)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(white: 0.4))
                        .lineSpacing(5)
                        .italic()
                        .padding(.bottom, 40)

                    Text("based on \(pattern.thinkCount) thinks")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(white: 0.2))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
    }
}
