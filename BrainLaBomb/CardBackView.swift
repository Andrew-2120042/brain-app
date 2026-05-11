import SwiftUI

struct CardBackView: View {
    let result: DecisionResult
    let originalQuestion: String
    let thinkID: UUID
    @ObservedObject var viewModel: AppViewModel
    let onChatMessagesUpdated: ([ChatBubble]) -> Void
    var onNewThink: (() -> Void)? = nil

    @State private var showStories = false
    @State private var showChat = false
    @State private var showPaywall = false
    @State private var chatMessages: [ChatBubble]
    #if DEBUG
    @State private var debugForceVerdict = false
    #endif

    var isPro: Bool { false } // TODO: replace with RevenueCat check

    init(result: DecisionResult,
         originalQuestion: String,
         viewModel: AppViewModel,
         thinkID: UUID,
         existingChatMessages: [ChatBubble],
         onChatMessagesUpdated: @escaping ([ChatBubble]) -> Void,
         onNewThink: (() -> Void)? = nil) {
        self.result = result
        self.originalQuestion = originalQuestion
        self._viewModel = ObservedObject(initialValue: viewModel)
        self.thinkID = thinkID
        self.onChatMessagesUpdated = onChatMessagesUpdated
        self.onNewThink = onNewThink
        self._chatMessages = State(initialValue: existingChatMessages)
    }

    private var verdictIsTruncated: Bool {
        #if DEBUG
        return result.verdict.split(separator: " ").count > 7 || debugForceVerdict
        #else
        return result.verdict.split(separator: " ").count > 7
        #endif
    }

    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 0) {

                // ── Full verdict (only when front text is cut off) ────
                if verdictIsTruncated {
                    Text(result.verdict.lowercased())
                        .font(.custom("Poppins-Regular", size: 18))
                        .foregroundColor(.white)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 18)
                        .padding(.top, 18)
                        .padding(.bottom, 14)
                }

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
                .padding(.top, verdictIsTruncated ? 0 : 22)

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

                // ── Buttons ───────────────────────────────────────────
                VStack(spacing: 8) {
                    #if DEBUG
                    Button { debugForceVerdict.toggle() } label: {
                        Text("VERB")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(debugForceVerdict ? Color.black : Color(white: 0.55))
                            .frame(width: 50, height: 28)
                            .background(debugForceVerdict ? Color.white : Color(white: 0.14))
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    #endif
                    Button { if isPro { showChat = true } else { showPaywall = true } } label: {
                        HStack {
                            Text("chat about this")
                                .font(.custom("Poppins-Regular", size: 15))
                                .foregroundColor(.white)
                            Spacer()
                            if !isPro {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(white: 0.45))
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.039, green: 0.039, blue: 0.039))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white, lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())

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
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 20)
                .fullScreenCover(isPresented: $showStories) {
                    StoriesView(
                        result: result,
                        viewModel: viewModel,
                        onContinueInChat: {
                            showStories = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showChat = true
                            }
                        },
                        onNewThink: {
                            showStories = false
                            onNewThink?()
                        }
                    )
                }
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
                }
                .fullScreenCover(isPresented: $showChat) {
                    ChatView(
                        originalQuestion: originalQuestion,
                        decisionResult: result,
                        viewModel: viewModel,
                        thinkID: thinkID,
                        existingMessages: chatMessages,
                        onMessagesUpdated: { updated in
                            chatMessages = updated
                            onChatMessagesUpdated(updated)
                        },
                        onNewThink: onNewThink
                    )
                }
            }
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
