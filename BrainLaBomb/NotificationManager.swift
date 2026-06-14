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

    static let trialReminderIdentifiers = ["trial-reminder-day-6", "trial-reminder-day-7"]

    func scheduleTrialReminders() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            let day6Content = UNMutableNotificationContent()
            day6Content.title = "bracket"
            day6Content.body = "your free trial ends tomorrow. don't lose your clarity."
            day6Content.sound = .default

            let day7Content = UNMutableNotificationContent()
            day7Content.title = "bracket"
            day7Content.body = "your free trial ends today. upgrade to keep going."
            day7Content.sound = .default

            let intervals: [(content: UNMutableNotificationContent, days: Int)] = [
                (day6Content, 6),
                (day7Content, 7)
            ]

            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: Self.trialReminderIdentifiers
            )

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
    }

    func cancelTrialReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: Self.trialReminderIdentifiers
        )
    }

    // MARK: - Re-engagement for free-tier users who skipped both paywalls

    static let reEngagementIdentifiers = [
        "bracket.reengagement.day1",
        "bracket.reengagement.day3",
        "bracket.reengagement.day7"
    ]

    func scheduleReEngagementNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            let day1 = UNMutableNotificationContent()
            day1.title = "still thinking it over?"
            day1.body = "bracket is here when you're ready."
            day1.sound = .default

            let day3 = UNMutableNotificationContent()
            day3.title = "got a decision to make?"
            day3.body = "open bracket and think it through."
            day3.sound = .default

            let day7 = UNMutableNotificationContent()
            day7.title = "your first think is waiting."
            day7.body = "try bracket free for 7 days — no commitment."
            day7.sound = .default

            let items: [(id: String, content: UNMutableNotificationContent, days: Int)] = [
                ("bracket.reengagement.day1", day1, 1),
                ("bracket.reengagement.day3", day3, 3),
                ("bracket.reengagement.day7", day7, 7)
            ]

            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: Self.reEngagementIdentifiers
            )

            for item in items {
                let trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: TimeInterval(item.days * 24 * 60 * 60),
                    repeats: false
                )
                let request = UNNotificationRequest(
                    identifier: item.id,
                    content: item.content,
                    trigger: trigger
                )
                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    func cancelReEngagementNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: Self.reEngagementIdentifiers
        )
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Weekly trial ending reminder

    static let weeklyTrialEndingIdentifier = "bracket.weekly.trial.ending"

    func scheduleWeeklyTrialEndingReminder() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = "your trial ends tomorrow."
            content.body = "keep thinking clearly with bracket."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: 6 * 24 * 60 * 60,
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: Self.weeklyTrialEndingIdentifier,
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: [Self.weeklyTrialEndingIdentifier]
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    func cancelWeeklyTrialEndingReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Self.weeklyTrialEndingIdentifier]
        )
    }

    #if DEBUG
    /// Fires the same notification as the real day-6 reminder, but in 5 seconds.
    func scheduleWeeklyTrialEndingReminderTest() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = "your trial ends tomorrow."
            content.body = "keep thinking clearly with bracket."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(
                identifier: Self.weeklyTrialEndingIdentifier + ".test",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    /// Fires the day-6 and day-7 annual trial reminders in 5s and 10s.
    func scheduleTrialRemindersTest() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            let day6 = UNMutableNotificationContent()
            day6.title = "bracket"
            day6.body = "your free trial ends tomorrow. don't lose your clarity."
            day6.sound = .default

            let day7 = UNMutableNotificationContent()
            day7.title = "bracket"
            day7.body = "your free trial ends today. upgrade to keep going."
            day7.sound = .default

            let items: [(id: String, content: UNMutableNotificationContent, delay: TimeInterval)] = [
                ("trial-reminder-day-6.test", day6, 5),
                ("trial-reminder-day-7.test", day7, 10)
            ]

            for item in items {
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: item.delay, repeats: false)
                let request = UNNotificationRequest(identifier: item.id, content: item.content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    /// Fires all 3 re-engagement notifications in 5s, 10s, 15s.
    func scheduleReEngagementNotificationsTest() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            let day1 = UNMutableNotificationContent()
            day1.title = "still thinking it over?"
            day1.body = "bracket is here when you're ready."
            day1.sound = .default

            let day3 = UNMutableNotificationContent()
            day3.title = "got a decision to make?"
            day3.body = "open bracket and think it through."
            day3.sound = .default

            let day7 = UNMutableNotificationContent()
            day7.title = "your first think is waiting."
            day7.body = "try bracket free for 7 days — no commitment."
            day7.sound = .default

            let items: [(id: String, content: UNMutableNotificationContent, delay: TimeInterval)] = [
                ("bracket.reengagement.day1.test", day1, 5),
                ("bracket.reengagement.day3.test", day3, 10),
                ("bracket.reengagement.day7.test", day7, 15)
            ]

            for item in items {
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: item.delay, repeats: false)
                let request = UNNotificationRequest(identifier: item.id, content: item.content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    #endif

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
