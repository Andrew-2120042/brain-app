import SwiftUI

struct HistoryPanelView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: AppViewModel
    let onChatMessagesUpdated: (UUID, [ChatBubble]) -> Void

    @AppStorage("debug_useMockData") private var useMockData: Bool = false
    @State private var selectedThink: Think? = nil

    private var displayThinks: [Think] {
        let history = Array(viewModel.thinkHistory.reversed())
        #if DEBUG
        if useMockData && history.isEmpty {
            return [
                Think(originalQuestion: "should I quit my job to freelance full time?", result: .mock),
                Think(originalQuestion: "is it worth moving to a new city for this opportunity?", result: .mock)
            ]
        }
        #endif
        return history
    }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var body: some View {
        ZStack {
            Color.black

            VStack(alignment: .leading, spacing: 0) {
                headerView
                Rectangle()
                    .fill(Color(white: 0.1))
                    .frame(height: 0.5)

                if displayThinks.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(displayThinks) { think in
                                Button {
                                    selectedThink = think
                                } label: {
                                    thinkRow(think)
                                }
                                .buttonStyle(PlainButtonStyle())
                                Rectangle()
                                    .fill(Color(white: 0.08))
                                    .frame(height: 0.5)
                            }
                        }
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedThink) { think in
            DecisionCardView(
                result: think.result,
                originalQuestion: think.originalQuestion,
                onReset: { selectedThink = nil },
                viewModel: viewModel,
                thinkID: think.id,
                existingChatMessages: think.chatMessages,
                onChatMessagesUpdated: { updatedMessages in
                    onChatMessagesUpdated(think.id, updatedMessages)
                }
            )
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("HISTORY")
                    .font(.custom("Poppins-Regular", size: 22))
                    .foregroundColor(.white)
                Text("your past thinks")
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(Color(hex: "#666666"))
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isPresented = false
                }
            } label: {
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
        .padding(.bottom, 20)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 6) {
            Spacer()
            Text("no thinks yet.")
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(Color(white: 0.3))
            Text("your decisions will appear here.")
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(Color(hex: "#444444"))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Think Row

    private func thinkRow(_ think: Think) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(think.originalQuestion)
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundColor(.white)
                .lineLimit(1)

            HStack(alignment: .center) {
                Text(dateFormatter.string(from: think.timestamp))
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(Color(hex: "#666666"))

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    HStack(alignment: .bottom, spacing: 2) {
                        Text("\(think.result.confidence)")
                            .font(.custom("Poppins-Regular", size: 18))
                            .foregroundColor(.white)
                        Text("%")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(Color(white: 0.5))
                            .padding(.bottom, 2)
                    }
                    Text("confidence")
                        .font(.custom("Poppins-Regular", size: 10))
                        .foregroundColor(Color(hex: "#444444"))
                    if !think.chatMessages.filter({ !$0.isContextCard }).isEmpty {
                        Text("chat saved")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(Color(white: 0.35))
                            .padding(.top, 2)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

}
