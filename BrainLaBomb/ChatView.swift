import SwiftUI
import CoreMotion

// MARK: - Chat Bubble Model

struct ChatBubble: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let isContextCard: Bool

    init(content: String, isUser: Bool, isContextCard: Bool) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.isContextCard = isContextCard
    }
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Rounded Corner Shape

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

private extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - ChatView

struct ChatView: View {
    let originalQuestion: String
    let decisionResult: DecisionResult
    @ObservedObject var viewModel: AppViewModel
    let thinkID: UUID
    let existingMessages: [ChatBubble]
    let onMessagesUpdated: ([ChatBubble]) -> Void
    var onNewThink: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var messages: [ChatBubble] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var showStories: Bool = false
    @FocusState private var inputFocused: Bool

    // Gyro
    @State private var tiltX: Double = 0
    @State private var tiltY: Double = 0
    private static let motion = CMMotionManager()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(messages) { bubble in
                                messageBubbleView(bubble)
                                    .id(bubble.id)
                            }
                            if isLoading {
                                typingIndicator
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                    }
                    .scrollDismissesKeyboard(.immediately)
                    .simultaneousGesture(TapGesture().onEnded { inputFocused = false })
                    .onChange(of: messages.count) { _ in
                        DispatchQueue.main.async {
                            withAnimation(.easeOut(duration: 0.2)) {
                                if let lastId = messages.last?.id {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onChange(of: isLoading) { _ in
                        DispatchQueue.main.async {
                            withAnimation(.easeOut(duration: 0.2)) {
                                if isLoading { proxy.scrollTo("typing", anchor: .bottom) }
                            }
                        }
                    }
                }

                inputBar
            }
        }
        .onAppear {
            if messages.isEmpty {
                if existingMessages.isEmpty {
                    messages.append(ChatBubble(content: "", isUser: false, isContextCard: true))
                } else {
                    messages = existingMessages
                }
            }
            startGyro()
        }
        .onDisappear {
            Self.motion.stopDeviceMotionUpdates()
        }
        .fullScreenCover(isPresented: $showStories) {
            StoriesView(
                result: decisionResult,
                viewModel: viewModel,
                onContinueInChat: { showStories = false },
                onNewThink: {
                    showStories = false
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        onNewThink?()
                    }
                }
            )
        }
    }

    // MARK: - Gyro

    private func startGyro() {
        guard Self.motion.isDeviceMotionAvailable else { return }
        Self.motion.deviceMotionUpdateInterval = 1.0 / 60.0
        Self.motion.startDeviceMotionUpdates(to: .main) { data, _ in
            guard let data = data else { return }
            let y = data.gravity.x * -28
            let x = (data.gravity.y + 0.6) * 28
            withAnimation(.easeOut(duration: 0.1)) {
                tiltY = max(-20, min(20, y))
                tiltX = max(-20, min(20, x))
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        ZStack {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "#666666"))
                        .frame(width: 44, height: 44)
                }
                .padding(.trailing, 4)
            }
        }
        .frame(height: 44)
        .overlay(
            Rectangle()
                .fill(Color(hex: "#1A1A1A"))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - Message Bubbles

    @ViewBuilder
    private func messageBubbleView(_ bubble: ChatBubble) -> some View {
        if bubble.isContextCard {
            contextCardView
                .rotation3DEffect(.degrees(tiltX), axis: (1, 0, 0), perspective: 0.6)
                .rotation3DEffect(.degrees(tiltY), axis: (0, 1, 0), perspective: 0.6)
        } else if bubble.isUser {
            HStack {
                Spacer()
                Text(bubble.content)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(18)
                    .cornerRadius(4, corners: .bottomRight)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
            }
        } else {
            HStack {
                Text(bubble.content)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .lineSpacing(6)
                    .padding(.leading, 4)
                Spacer()
            }
        }
    }

    // MARK: - Context Card

    private var contextCardView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(decisionResult.verdict)
                .font(.custom("Poppins-Regular", size: 20))
                .foregroundColor(.white)

            HStack(alignment: .bottom, spacing: 2) {
                Text("\(decisionResult.confidence)")
                    .font(.custom("Poppins-Regular", size: 32))
                    .foregroundColor(.white)
                Text("%")
                    .font(.custom("Poppins-Regular", size: 20))
                    .foregroundColor(.white)
                    .padding(.bottom, 4)
            }

            Rectangle()
                .fill(Color(hex: "#333333"))
                .frame(height: 0.5)

            Button(action: { showStories = true }) {
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
        .padding(16)
        .background(Color(hex: "#1A1A1A"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "#333333"), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color(hex: "#666666"))
                    .frame(width: 6, height: 6)
                    .scaleEffect(isLoading ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(index) * 0.15),
                        value: isLoading
                    )
            }
            Spacer()
        }
        .padding(.leading, 4)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        let canSend = !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading

        return HStack(alignment: .center, spacing: 10) {
            TextField("ask something about this...", text: $inputText, axis: .vertical)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .tint(.white)
                .focused($inputFocused)
                .lineLimit(1...5)
                .onSubmit { sendMessage() }

            Button(action: sendMessage) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 34, height: 34)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canSend)
            .opacity(canSend ? 1.0 : 0.3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(hex: "#1C1C1E"))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .padding(.top, 8)
    }

    // MARK: - Send

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty && !isLoading else { return }

        inputText = ""
        messages.append(ChatBubble(content: text, isUser: true, isContextCard: false))
        onMessagesUpdated(messages)
        isLoading = true

        Task {
            do {
                let reply = try await fetchChatReply(userMessage: text)
                await MainActor.run {
                    isLoading = false
                    messages.append(ChatBubble(content: reply, isUser: false, isContextCard: false))
                    onMessagesUpdated(messages)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    messages.append(ChatBubble(
                        content: "something went wrong. try again.",
                        isUser: false,
                        isContextCard: false
                    ))
                }
            }
        }
    }

    // MARK: - API

    private func fetchChatReply(userMessage: String) async throws -> String {
        if Constants.useMockData {
            try await Task.sleep(nanoseconds: 800_000_000)
            return "That's a fair question. The core issue here is that the short-term gain doesn't offset the long-term cost to your energy. Trust the original read."
        }

        let systemPrompt = """
        You are a decision-making brain. You already gave this person a decision.
        Now they are asking follow up questions about it.

        The original situation: \(originalQuestion)
        Your verdict: \(decisionResult.verdict)
        Your confidence: \(decisionResult.confidence)%
        Your reasoning: \(decisionResult.report.reasoning.joined(separator: " "))

        Stay in character at all times. You are the same brain that gave the original decision.
        Answer only questions related to this decision and its context.
        If they ask something completely unrelated redirect them back naturally.

        Keep responses short. 2-4 sentences maximum.
        Talk like a person not a report. No bullet points. No lists.
        Direct sentences only. Second person. Present tense.
        Never mention AI, simulations, or that you are a language model.
        Never say I understand, it seems like, that's a great question.
        """

        // Build history from messages already in state (user message was appended before this call)
        // Do NOT append userMessage again — that would create two consecutive user turns which the API rejects
        let apiMessages: [[String: Any]] = messages.suffix(10).compactMap { bubble in
            guard !bubble.isContextCard else { return nil }
            return ["role": bubble.isUser ? "user" : "assistant", "content": bubble.content]
        }

        let body: [String: Any] = [
            "model": Constants.model,
            "max_tokens": 300,
            "system": systemPrompt,
            "messages": apiMessages
        ]

        guard let url = URL(string: Constants.baseURL) else { throw APIError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Constants.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Constants.anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            throw APIError.invalidResponse
        }

        return text
    }
}
