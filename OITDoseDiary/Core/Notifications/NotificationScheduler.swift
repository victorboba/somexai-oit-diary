import Foundation
import UserNotifications

/// Two local notifications only: a daily dose reminder per plan, and a one-shot "rest period is over".
/// Permission is requested the first time either is needed, never at launch.
enum NotificationScheduler {
    static func ensurePermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .denied:
            return false
        default:
            return true
        }
    }

    static func reminderID(_ planID: UUID) -> String { "reminder.\(planID.uuidString)" }
    static func restID(_ planID: UUID) -> String { "rest.\(planID.uuidString)" }

    static func scheduleDailyReminder(planID: UUID, enabled: Bool, hour: Int, minute: Int, body: String) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderID(planID)])
        guard enabled, await ensurePermission() else { return }

        let content = UNMutableNotificationContent()
        content.title = AppConfig.appName
        content.body = body
        content.sound = .default
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        try? await center.add(UNNotificationRequest(identifier: reminderID(planID), content: content, trigger: trigger))
    }

    static func cancelDailyReminder(planID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderID(planID)])
    }

    static func scheduleRestOver(planID: UUID, doseTakenAt: Date, restMinutes: Int, planTitle: String) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [restID(planID)])
        let fireAt = doseTakenAt.addingTimeInterval(TimeInterval(restMinutes * 60))
        let seconds = fireAt.timeIntervalSinceNow
        guard seconds > 1, await ensurePermission() else { return }

        let content = UNMutableNotificationContent()
        content.title = AppConfig.appName
        content.body = "Rest period after \(planTitle)'s dose is over."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: restID(planID), content: content, trigger: trigger))
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
