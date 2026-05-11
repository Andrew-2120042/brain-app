import SwiftUI
import UserNotifications

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = false
    @State private var showResetConfirmation = false
    @State private var showPaywall = false

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
                        dangerSection
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear { checkNotificationStatus() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("settings")
                .font(.custom("HelveticaNeue", size: 28))
                .foregroundColor(.white)
            Spacer()
            Button { dismiss() } label: {
                Text("done")
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
            settingsRow(
                label: "thinks used",
                value: viewModel.thinksRemaining <= 0
                    ? "limit reached"
                    : "\(viewModel.thinksUsed) of \(Constants.maxFreeThinks)"
            )
            Button { showPaywall = true } label: {
                Text("unlock unlimited thinks")
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

    private var notificationsSection: some View {
        VStack(spacing: 0) {
            sectionHeader("notifications")

            HStack {
                Text("weekly nudge")
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

            Text("once a week. never spam.")
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
            settingsRow(label: "privacy policy", action: {
                if let url = URL(string: "https://brainlabomb.com/privacy") {
                    UIApplication.shared.open(url)
                }
            })
            settingsRow(label: "terms of service", action: {
                if let url = URL(string: "https://brainlabomb.com/terms") {
                    UIApplication.shared.open(url)
                }
            })
            settingsRow(
                label: "version",
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
            settingsRow(label: "send feedback", action: {
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                let body = "App version: \(version)\n\n"
                let urlString = "mailto:godiandrewwilson@gmail.com?subject=Feedback&body=\(body)"
                    .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                if let url = URL(string: urlString) {
                    UIApplication.shared.open(url)
                }
            })
            Text("opens your mail app. we read everything.")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(white: 0.3))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 14)
        }
    }

    private var dangerSection: some View {
        VStack(spacing: 0) {
            sectionHeader("data")
            Button { showResetConfirmation = true } label: {
                HStack {
                    Text("delete all thinks")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
            }
            Text("permanently deletes all your thinks and chat history from this device. cannot be undone.")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(white: 0.3))
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
        .alert("delete everything?", isPresented: $showResetConfirmation) {
            Button("cancel", role: .cancel) {}
            Button("delete everything", role: .destructive) {
                viewModel.clearAllData()
            }
        } message: {
            Text("this will permanently delete all your thinks and chat history. this cannot be undone.")
        }
    }

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
                        NotificationManager.shared.scheduleWeeklyNotification()
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
