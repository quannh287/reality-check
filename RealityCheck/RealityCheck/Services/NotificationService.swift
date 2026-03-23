import Foundation
import UserNotifications

enum NotificationService {
    static let dailyReminderID = "daily-reality-check"

    static func buildContent(for card: RealityCard?) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Reality Check"
        if let card {
            let value = FormulaEngine.displayValue(for: card)
            content.body = "\(value) \(card.unit) — \(card.contextLine)"
        } else {
            content.body = "Mở app để tạo Reality Card đầu tiên"
        }
        content.sound = .default
        return content
    }

    static func buildDailyTrigger(hour: Int, minute: Int) -> UNCalendarNotificationTrigger {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    }

    static func scheduleDailyNotification(
        for card: RealityCard?,
        hour: Int,
        minute: Int
    ) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderID])

        let content = buildContent(for: card)
        let trigger = buildDailyTrigger(hour: hour, minute: minute)
        let request = UNNotificationRequest(
            identifier: dailyReminderID,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    static func cancelDailyNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [dailyReminderID])
    }

    static func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
