import UserNotifications

struct NotificationManager {

    static let shared = NotificationManager()
    private init() {}

    private let notificationMessages = [
        "something on your mind?",
        "your brain is ready when you are.",
        "what are you avoiding thinking about?",
        "one decision. thirty seconds. bracket.",
        "the answer is already there. let's find it.",
        "what would you do if you knew you wouldn't fail?",
        "stop carrying it alone.",
        "clarity is closer than you think.",
        "what's the one thing you keep putting off?",
        "your next move is clearer than you think.",
        "the brain is ready. are you?",
        "what decision have you been avoiding?",
        "think it through. just once.",
        "you already know what needs to happen.",
        "one think a day keeps the overthinking away.",
        "what would the simulation say?",
        "bring it something real today.",
        "decisions get harder the longer you wait.",
        "the brain learns every time you use it.",
        "what's on your mind right now?",
        "clarity doesn't come from waiting.",
        "one question. thousands of outcomes.",
        "what are you really choosing between?",
        "the right move exists. let's find it.",
        "your pattern is becoming clearer.",
        "what would you decide if you weren't scared?",
        "stop overthinking. start deciding.",
        "the answer lives in the simulation.",
        "what's the decision you keep circling back to?",
        "bring bracket your hardest question today.",
        "every choice is a simulation waiting to happen.",
        "what would you do with perfect clarity?",
        "the brain remembers how you think.",
        "one decision at a time.",
        "what's holding you back from deciding?",
        "clarity is a muscle. use it.",
        "your next chapter starts with one decision.",
        "what would future you thank you for deciding today?",
        "the simulation is waiting.",
        "stop guessing. start knowing.",
        "what's the thing you need to think through?",
        "decisions made with clarity stick.",
        "what would the data say?",
        "your brain works best when you use it.",
        "one think changes everything.",
        "what are you really afraid of choosing?",
        "the answer isn't in your head. it's in the simulation.",
        "make the decision. see the outcomes.",
        "clarity before commitment.",
        "what's the move?"
    ]

    func scheduleDailyNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        for i in 0..<7 {
            let content = UNMutableNotificationContent()
            content.title = "bracket"
            content.body = notificationMessages.randomElement() ?? "something on your mind?"
            content.sound = .default

            var components = DateComponents()
            components.hour = Int.random(in: 10...14)
            components.minute = Int.random(in: 0...59)

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents(
                    [.hour, .minute],
                    from: Calendar.current.date(byAdding: .day, value: i + 1, to: Date())!
                ),
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "daily-brain-nudge-\(i)",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
        }
    }

    func scheduleTrialReminders() {
        let day3Content = UNMutableNotificationContent()
        day3Content.title = "bracket"
        day3Content.body = "4 days left on your free trial. still thinking?"
        day3Content.sound = .default

        let day4Content = UNMutableNotificationContent()
        day4Content.title = "bracket"
        day4Content.body = "3 days left on your free trial. don't stop now."
        day4Content.sound = .default

        let day5Content = UNMutableNotificationContent()
        day5Content.title = "bracket"
        day5Content.body = "2 days left on your free trial. keep thinking clearly."
        day5Content.sound = .default

        let day6Content = UNMutableNotificationContent()
        day6Content.title = "bracket"
        day6Content.body = "last day of your free trial tomorrow. don't lose your clarity."
        day6Content.sound = .default

        let day7Content = UNMutableNotificationContent()
        day7Content.title = "bracket"
        day7Content.body = "your free trial ends today. upgrade to keep going."
        day7Content.sound = .default

        let intervals: [(content: UNMutableNotificationContent, days: Int)] = [
            (day3Content, 3),
            (day4Content, 4),
            (day5Content, 5),
            (day6Content, 6),
            (day7Content, 7)
        ]

        for item in intervals {
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(item.days * 24 * 60 * 60),
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: "trial-reminder-day-\(item.days)",
                content: item.content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
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
        content.title = "bracket"
        content.body = notificationMessages.randomElement() ?? "something on your mind?"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
    #endif
}
