import SwiftUI

struct CardBackView: View {
    let result: DecisionResult
    let originalQuestion: String
    let thinkID: UUID
    let layoutIndex: Int
    @ObservedObject var viewModel: AppViewModel
    let onChatMessagesUpdated: ([ChatBubble]) -> Void
    var onNewThink: (() -> Void)? = nil
    var onScrollingChanged: ((Bool) -> Void)? = nil

    @State private var showStories = false
    @State private var showChat = false
    @State private var showPaywall = false
    @State private var chatMessages: [ChatBubble]
    #if DEBUG
    @State private var debugForceVerdict = false
    #endif

    private var canChat: Bool {
        #if DEBUG
        return viewModel.debugTier == .pro
        #else
        return false // TODO: RevenueCat
        #endif
    }

    init(result: DecisionResult,
         originalQuestion: String,
         viewModel: AppViewModel,
         thinkID: UUID,
         layoutIndex: Int,
         existingChatMessages: [ChatBubble],
         onChatMessagesUpdated: @escaping ([ChatBubble]) -> Void,
         onNewThink: (() -> Void)? = nil,
         onScrollingChanged: ((Bool) -> Void)? = nil) {
        self.result = result
        self.originalQuestion = originalQuestion
        self._viewModel = ObservedObject(initialValue: viewModel)
        self.thinkID = thinkID
        self.layoutIndex = layoutIndex
        self.onChatMessagesUpdated = onChatMessagesUpdated
        self.onNewThink = onNewThink
        self.onScrollingChanged = onScrollingChanged
        self._chatMessages = State(initialValue: existingChatMessages)
    }

    private var verdictIsTruncated: Bool {
        #if DEBUG
        if debugForceVerdict { return true }
        #endif
        // Character count is more accurate than word count because minimumScaleFactor
        // lets the text shrink to fit more characters per line than word count suggests.
        // Thresholds derived from card content width (~261pt natural) and Poppins metrics
        // at each layout's minimum rendered font size.
        // A  — font 20, minScale 0.7 → 14pt, lineLimit 2, full width  → ~74 chars max → threshold 72
        // D  — font 24, minScale 0.7 → 16.8pt, lineLimit 4, 55% width → ~65 chars max → threshold 63
        // B/C/E — font 26, minScale 0.75 → 19.5pt, lineLimit 3, full  → ~78 chars max → threshold 76
        let charCount = result.verdict.count
        let threshold: Int
        switch layoutIndex {
        case 0:  threshold = 72
        case 3:  threshold = 63
        default: threshold = 76
        }
        return charCount > threshold
    }

    var body: some View {
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

            // ── Scrollable Why + Trade offs ───────────────────────
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Why
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

                    // Trade offs
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
                    .padding(.bottom, 16)
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { _ in onScrollingChanged?(true) }
                    .onEnded { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            onScrollingChanged?(false)
                        }
                    }
            )

            // ── Fixed buttons ─────────────────────────────────────
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

                Button { if canChat { showChat = true } else { showPaywall = true } } label: {
                    HStack {
                        Text("chat about this")
                            .font(.custom("Poppins-Regular", size: 15))
                            .foregroundColor(canChat ? .white : Color(white: 0.4))
                        Spacer()
                        if !canChat {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(white: 0.4))
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.039, green: 0.039, blue: 0.039))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(canChat ? Color.white : Color(white: 0.25), lineWidth: 1))
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
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
