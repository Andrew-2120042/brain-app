import SwiftUI
import UserNotifications

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = false
    @State private var showResetHistoryConfirmation = false
    @State private var showPaywall = false
    @State private var showDocs = false
    @State private var docsTab = 0
    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A").ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        brainSection
                        divider
                        notificationsSection
                        divider
                        aboutSection
                        divider
                        disclaimerSection
                        divider
                        feedbackSection
                        divider
                        helpSection
                        divider
                        testingSection
                        divider
                        dangerSection
                        #if DEBUG
                        divider
                        debugSection
                        #endif
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear { checkNotificationStatus() }
        .fullScreenCover(isPresented: $showPaywall) { PaywallView(viewModel: viewModel, onDismiss: { showPaywall = false }) }
        .sheet(isPresented: $showDocs) { DocsView(initialTab: docsTab) }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("Settings")
                .font(.custom("HelveticaNeue", size: 28))
                .foregroundColor(.white)
            Spacer()
            Button { dismiss() } label: {
                Text("Done")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(white: 0.5))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Sections

    private var brainSection: some View {
        VStack(spacing: 0) {
            sectionHeader("your brain")
            HStack {
                Text("Current Plan")
                    .font(.custom("HelveticaNeue", size: 15))
                    .foregroundColor(Color(white: 0.6))
                Spacer()
                Text(viewModel.tierDisplayLabel)
                    .font(.custom("HelveticaNeue", size: 15))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            if viewModel.hasActiveEntitlement && viewModel.currentTier == .core {
                settingsRow(
                    label: "Thinks Used",
                    value: "\(viewModel.coreThinksUsed) of \(viewModel.coreThinkLimit)"
                )
                settingsRow(
                    label: "\(viewModel.coreThinksRemaining) Thinks Remaining",
                    value: nil
                )
            } else if viewModel.hasActiveEntitlement {
                settingsRow(
                    label: "Chat Messages This Month",
                    value: "\(viewModel.monthlyChatCount)"
                )
                settingsRow(
                    label: "Thinks Used Total",
                    value: "\(viewModel.thinksUsed)"
                )
            }
            if !viewModel.isOnProAnnual {
                Button { showPaywall = true } label: {
                    Text("Unlock Unlimited Thinks")
                        .font(.custom("HelveticaNeue", size: 15))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
        }
    }

    private var notificationsSection: some View {
        VStack(spacing: 0) {
            sectionHeader("notifications")

            HStack {
                Text("Daily Notifications")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white)
                Spacer()
                Toggle("", isOn: $notificationsEnabled)
                    .labelsHidden()
                    .tint(Color.white)
                    .onChange(of: notificationsEnabled) { enabled in
                        handleNotificationToggle(enabled)
                    }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)

            Text("Once a day. Always relevant.")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(white: 0.3))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 14)
        }
    }

    private var aboutSection: some View {
        VStack(spacing: 0) {
            sectionHeader("about")
            settingsRow(label: "Privacy Policy", action: {
                docsTab = 1
                showDocs = true
            })
            settingsRow(label: "Terms of Service", action: {
                docsTab = 0
                showDocs = true
            })
            settingsRow(
                label: "Version",
                value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            )
        }
    }

    private var disclaimerSection: some View {
        VStack(spacing: 0) {
            sectionHeader("disclaimer")
            Text("This app uses AI to simulate possible outcomes and provide perspective. It is not professional medical, legal, financial, or mental health advice. Always consult a qualified professional for important decisions.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(white: 0.35))
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
    }

    private var feedbackSection: some View {
        VStack(spacing: 0) {
            sectionHeader("feedback")
            settingsRow(label: "Send Feedback", action: {
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                let body = "App version: \(version)\n\n"
                let urlString = "mailto:bracketapp26@gmail.com?subject=Feedback&body=\(body)"
                    .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                if let url = URL(string: urlString) {
                    UIApplication.shared.open(url)
                }
            })
            Text("We read everything.")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(white: 0.3))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 14)

            Button(action: {
                let email = "bracketapp26@gmail.com"
                let subject = "Feature Request"
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                let body = "App version: \(version)\n\nFeature request:\n"
                let urlString = "mailto:\(email)?subject=\(subject)&body=\(body)"
                    .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                if let url = URL(string: urlString) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Text("Request a Feature")
                        .font(.custom("HelveticaNeue", size: 15))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.3))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
            }

            Text("Got an idea? We want to hear it.")
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(Color(white: 0.3))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 14)
        }
    }

    private var helpSection: some View {
        VStack(spacing: 0) {
            sectionHeader("need help?")
            Button(action: {
                let email = "bracketapp26@gmail.com"
                let subject = "Need Help"
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                let body = "App version: \(version)\n\nDescribe the issue:\n"
                let urlString = "mailto:\(email)?subject=\(subject)&body=\(body)"
                    .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                if let url = URL(string: urlString) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Text("Contact Support")
                        .font(.custom("HelveticaNeue", size: 15))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.3))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
            }

            Text("Stuck or something not working? We'll get back to you.")
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(Color(white: 0.3))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 14)
        }
    }

    // TEMP — visible in release for TestFlight UI testing. Remove before App Store submission.
    private var testingSection: some View {
        VStack(spacing: 0) {
            sectionHeader("testing")
            settingsRow(label: "Show In-App Paywall", action: {
                showPaywall = true
            })
            settingsRow(label: "Show Onboarding Paywall", action: {
                UserDefaults.standard.set(true, forKey: "test_jumpToPaywallStep")
                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                UserDefaults.standard.removeObject(forKey: Constants.onboardingProgressKey)
                NotificationCenter.default.post(name: .replayOnboarding, object: nil)
                dismiss()
            })
            Text("Temporary — remove before release.")
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(Color(white: 0.3))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 14)
        }
    }

    private var dangerSection: some View {
        VStack(spacing: 0) {
            sectionHeader("data")

            Button { showResetHistoryConfirmation = true } label: {
                HStack {
                    Text("Clear Think History")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
            }
            Text("Removes all your thinks and resets the brain's memory of you. Your account and usage are kept.")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(white: 0.3))
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
        .alert("Clear Think History?", isPresented: $showResetHistoryConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear History", role: .destructive) {
                viewModel.resetBrainMemory()
                dismiss()
            }
        } message: {
            Text("This removes all your thinks, pattern data, and memory. Cannot be undone.")
        }
    }

    #if DEBUG
    @AppStorage("useConversationalOnboarding") private var useConversational = true
    @AppStorage("useNumericIntro") private var useNumericIntro = false
    @AppStorage("debug_currencyPreview") private var currencyPreview = "off"

    private let currencyCycle = ["off", "USD", "GBP", "SGD"]

    private var debugSection: some View {
        VStack(spacing: 0) {
            sectionHeader("debug")
            settingsRow(label: "Replay Onboarding", action: {
                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                UserDefaults.standard.removeObject(forKey: Constants.onboardingProgressKey)
                NotificationCenter.default.post(name: .replayOnboarding, object: nil)
                dismiss()
            })
            settingsRow(label: "Test Loading Screen", action: {
                dismiss()
                viewModel.appState = .processingFirst
            })
            settingsRow(label: "Reset Payment (Local)", action: {
                viewModel.hasActiveEntitlement = false
                viewModel.purchasedTier = .core
                viewModel.activeProductIdentifier = nil
            })
            settingsRow(label: "Test Weekly Trial-Ending Notif (5s)", action: {
                NotificationManager.shared.scheduleWeeklyTrialEndingReminderTest()
            })
            settingsRow(label: "Test Annual Trial Reminders (5s, 10s)", action: {
                NotificationManager.shared.scheduleTrialRemindersTest()
            })
            settingsRow(label: "Test Re-Engagement Notifs (5s, 10s, 15s)", action: {
                NotificationManager.shared.scheduleReEngagementNotificationsTest()
            })
            Button {
                let idx = (currencyCycle.firstIndex(of: currencyPreview) ?? 0) + 1
                currencyPreview = currencyCycle[idx % currencyCycle.count]
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Paywall Currency Preview")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white)
                        Text(currencyPreview == "off" ? "Using real prices" : "Showing \(currencyPreview) prices")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(white: 0.35))
                    }
                    Spacer()
                    Text(currencyPreview)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(currencyPreview == "off" ? Color(white: 0.35) : Color(red: 0.18, green: 0.78, blue: 0.72))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color(white: 0.10).clipShape(Capsule()))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
            }
            .buttonStyle(PlainButtonStyle())
            HStack {
                Text("Hide Debug UI")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white)
                Spacer()
                Toggle("", isOn: $viewModel.hideDebugUI)
                    .labelsHidden()
                    .tint(Color.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)

            HStack {
                Text("Conversational Onboarding")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white)
                Spacer()
                Toggle("", isOn: $useConversational)
                    .labelsHidden()
                    .tint(Color.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Numeric Intro Animation")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white)
                    Text(useNumericIntro ? "Version B (probability/numbers)" : "Version A (typewriter)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(white: 0.35))
                }
                Spacer()
                Toggle("", isOn: $useNumericIntro)
                    .labelsHidden()
                    .tint(Color.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)

        }
    }
    #endif

    // MARK: - Helpers

    private var divider: some View {
        Rectangle()
            .fill(Color(white: 0.1))
            .frame(height: 1)
            .padding(.horizontal, 24)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Color(white: 0.3))
            .tracking(1.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 12)
    }

    private func settingsRow(label: String, value: String? = nil, action: (() -> Void)? = nil) -> some View {
        Button { action?() } label: {
            HStack {
                Text(label)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(action != nil ? .white : Color(white: 0.6))
                Spacer()
                if let value = value {
                    Text(value)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(white: 0.4))
                }
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(white: 0.3))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
        .disabled(action == nil)
    }

    // MARK: - Notification helpers

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    private func handleNotificationToggle(_ enabled: Bool) {
        if enabled {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    if granted {
                        NotificationManager.shared.scheduleDailyNotification()
                        notificationsEnabled = true
                    } else {
                        notificationsEnabled = false
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
        } else {
            NotificationManager.shared.cancelAllNotifications()
        }
    }
}
