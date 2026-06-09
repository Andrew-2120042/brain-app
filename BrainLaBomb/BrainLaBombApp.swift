import SwiftUI
import UserNotifications
import RevenueCat
import Sentry
import PostHog

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

// TODO: RENAME — replace with final app name before App Store submission
@main
struct BrainLaBombApp: App {
    init() {
        SentrySDK.start { options in
            options.dsn = "https://21df5dfa1a30db251f0c4b9698427965@o4511494874529792.ingest.us.sentry.io/4511494882656256"
            options.debug = false
            options.tracesSampleRate = 0.2
            options.configureProfiling = { profiling in
                profiling.sessionSampleRate = 0.2
            }
            options.enableCrashHandler = true
            options.enableAppHangTracking = true
            options.attachScreenshot = false
        }

        let config = PostHogConfig(projectToken: "phc_u7CWspLs5fFf8osbTP4tTEQ5B88FZpJU8zsjJ7CaUQUj", host: "https://us.i.posthog.com")
        config.captureScreenViews = false
        config.captureApplicationLifecycleEvents = true
        PostHogSDK.shared.setup(config)

        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        Purchases.logLevel = .error
        Purchases.configure(withAPIKey: "appl_wxvcKxKidfnfbBJkrkKgKwfkmMI")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onReceive(NotificationCenter.default.publisher(
                    for: UIApplication.didBecomeActiveNotification)
                ) { _ in
                    NotificationManager.shared.checkPermissionStatus { granted in
                        if granted {
                            NotificationManager.shared.scheduleDailyNotification()
                        }
                    }
                }
        }
    }
}
