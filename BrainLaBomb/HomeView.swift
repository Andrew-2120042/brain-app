import SwiftUI
import UserNotifications

struct HomeView: View {
    let isProcessing: Bool
    @ObservedObject var viewModel: AppViewModel
    let onChatMessagesUpdated: (UUID, [ChatBubble]) -> Void
    let onTap: () -> Void

    @State private var homeVersion: Int = 0
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var historyDragOffset: CGFloat = 0
    @AppStorage("debug_useMockData") private var useMockData: Bool = true

    private let bgURL  = Bundle.main.url(forResource: "home_bg",  withExtension: "mp4")!
    private let bgURL5 = Bundle.main.url(forResource: "home_bg5", withExtension: "mp4")!

    private var historyXOffset: CGFloat {
        let sw = UIScreen.main.bounds.width
        return showHistory ? max(0, historyDragOffset) : -sw
    }

    private var historyDragGesture: some Gesture {
        DragGesture()
            .onChanged { v in
                if v.translation.width > 0 { historyDragOffset = v.translation.width }
            }
            .onEnded { v in
                let sw = UIScreen.main.bounds.width
                let dismiss = v.translation.width > sw * 0.3
                    || v.predictedEndTranslation.width > sw * 0.5
                if dismiss {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        historyDragOffset = sw
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
                        showHistory = false
                        historyDragOffset = 0
                    }
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        historyDragOffset = 0
                    }
                }
            }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            homeScreen

            HistoryPanelView(
                isPresented: $showHistory,
                viewModel: viewModel,
                onChatMessagesUpdated: onChatMessagesUpdated
            )
                .offset(x: historyXOffset)
                .ignoresSafeArea()
                .gesture(historyDragGesture)
                .allowsHitTesting(showHistory)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showHistory)
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
    }

    // MARK: - Home Screen

    private var homeScreen: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if homeVersion == 0 {
                LoopingVideoView(url: bgURL).ignoresSafeArea().scaleEffect(1.35)
            } else {
                LoopingVideoView(url: bgURL5).ignoresSafeArea().scaleEffect(1.35)
            }

            version1

            VStack {
                HStack(alignment: .center) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showHistory = true
                        }
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 44, height: 44)
                    }

                    Button {
                        useMockData.toggle()
                    } label: {
                        Text(useMockData ? "MOCK" : "LIVE")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(useMockData ? Color(white: 0.9) : Color(red: 0.4, green: 1.0, blue: 0.5))
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(
                                (useMockData ? Color(white: 0.18) : Color(red: 0.1, green: 0.25, blue: 0.12))
                                    .clipShape(Capsule())
                            )
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { homeVersion = (homeVersion + 1) % 2 }
                    } label: {
                        Text("v\(homeVersion + 1)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(white: 0.35))
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color(white: 0.12).clipShape(Capsule()))
                    }

                    #if DEBUG
                    Button {
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                            DispatchQueue.main.async {
                                if granted {
                                    NotificationManager.shared.scheduleTestNotification()
                                }
                            }
                        }
                    } label: {
                        Text("notif")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(white: 0.35))
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color(white: 0.12).clipShape(Capsule()))
                    }
                    Button {
                        viewModel.forceHaikuMode.toggle()
                    } label: {
                        Text(viewModel.forceHaikuMode ? "HAIKU" : "SONNET")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(viewModel.forceHaikuMode ? .orange : Color(white: 0.5))
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color(white: 0.12).clipShape(Capsule()))
                    }
                    Button {
                        switch viewModel.debugTier {
                        case .free: viewModel.debugTier = .core
                        case .core: viewModel.debugTier = .pro
                        case .pro:  viewModel.debugTier = .free
                        }
                    } label: {
                        Text(tierLabel)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(tierColor)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color(white: 0.12).clipShape(Capsule()))
                    }
                    Button {
                        viewModel.originalQuestion = "debug boundary"
                        viewModel.appState = .result(DecisionResult.boundary)
                    } label: {
                        Text("BDRY")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.red)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color(white: 0.12).clipShape(Capsule()))
                    }
                    #endif
                }
                .padding(.top, 0)
                .padding(.horizontal, 16)

                Spacer()
            }
        }
    }

    // MARK: - Version 1

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
                    Button(action: {
                        if viewModel.thinkLimitReached {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.appState = .paywallRequired
                            }
                        } else {
                            onTap()
                        }
                    }) {
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

                    #if !DEBUG
                    if viewModel.currentTier == .free && viewModel.thinksUsed < Constants.maxFreeThinks {
                        Text("\(viewModel.thinksRemaining) free thinks remaining")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(white: 0.3))
                    }
                    #endif
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 56)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Version 2

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

    #if DEBUG
    private var tierLabel: String {
        switch viewModel.debugTier {
        case .free: return "FREE"
        case .core: return "CORE"
        case .pro:  return "PRO"
        }
    }

    private var tierColor: Color {
        switch viewModel.debugTier {
        case .free: return Color(white: 0.5)
        case .core: return Color.blue
        case .pro:  return Color.green
        }
    }
    #endif
}

// MARK: - Processing indicator

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
