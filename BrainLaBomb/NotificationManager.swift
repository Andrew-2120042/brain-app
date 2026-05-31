import UserNotifications

// TODO: Add scheduleTrialReminders(trialStartDate: Date) function
// Schedules three local notifications automatically when trial begins:
// +24 hours: "2 days left on your free trial."
// +48 hours: "1 day left on your free trial."
// +72 hours: "your free trial ends today. upgrade to keep going."
// Call this from AppViewModel when RevenueCat confirms trial started.

struct NotificationManager {

    static let shared = NotificationManager()
    private init() {}

    private let notificationMessages = [
        "something on your mind?",
        "your brain is ready when you are.",
        "been a while. what's pulling at you?",
        "got a decision sitting with you?",
        "the brain hasn't heard from you in a while.",
        "something keeping you up?",
        "what would you do differently today?",
        "your next move. the brain's thinking."
    ]

    func scheduleWeeklyNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        let content = UNMutableNotificationContent()
        content.title = ""
        content.body = notificationMessages.randomElement() ?? "something on your mind?"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = Int.random(in: 1...7)
        dateComponents.hour    = Int.random(in: 19...21)
        dateComponents.minute  = Int.random(in: 0...59)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly-brain-nudge", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error { print("Notification scheduling error: \(error)") }
        }
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func checkPermissionStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }

    #if DEBUG
    func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.body = notificationMessages.randomElement() ?? "something on your mind?"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
    #endif
}
