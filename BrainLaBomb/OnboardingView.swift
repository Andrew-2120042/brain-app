import SwiftUI
import UserNotifications

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var currentScreen = 0

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A").ignoresSafeArea()

            switch currentScreen {
            case 0: screenOne.transition(.opacity)
            case 1: screenTwo.transition(.opacity)
            case 2: screenThree.transition(.opacity)
            default: screenOne.transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: currentScreen)
    }

    // MARK: - Screen 1

    private var screenOne: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                Text("you already know\nwhat you should do.")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(32 * 0.3)

                Spacer().frame(height: 20)

                Text("you just need something\nto think it through with you.")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(28 * 0.3)
            }

            Spacer()

            onboardingButton("I'm ready") {
                currentScreen = 1
            }
            .padding(.bottom, 52)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Screen 2

    private var screenTwo: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                Text("this isn't advice.")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 24)

                Text("it's your situation,\nrun through thousands\nof possible outcomes.\n\nthen handed back to you.")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(24 * 0.5)
            }

            Spacer()

            onboardingButton("that's different") {
                currentScreen = 2
            }
            .padding(.bottom, 52)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Screen 3

    private var screenThree: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                Text("decisions don't only happen\nduring business hours.")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(28 * 0.3)

                Spacer().frame(height: 20)

                Text("let the brain find you\nwhen something's sitting with you.")
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(22 * 0.5)
            }

            Spacer()

            VStack(spacing: 12) {
                onboardingButton("yes, find me") {
                    requestNotificationPermission { onComplete() }
                }

                Button {
                    onComplete()
                } label: {
                    Text("not yet")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 52)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private func onboardingButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func requestNotificationPermission(completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    NotificationManager.shared.scheduleWeeklyNotification()
                }
                completion()
            }
        }
    }
}
