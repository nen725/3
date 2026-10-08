import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    static let categoryID = "CRAFT_TIMER"
    static let actionComplete = "ACTION_COMPLETE"
    static let actionRestart = "ACTION_RESTART"
    static let actionSnooze = "ACTION_SNOOZE"

    private override init() {
        super.init()
    }

    func configure() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        let complete = UNNotificationAction(identifier: Self.actionComplete, title: "完成", options: [])
        let restart = UNNotificationAction(identifier: Self.actionRestart, title: "完成并重新开始", options: [])
        let snooze = UNNotificationAction(identifier: Self.actionSnooze, title: "稍后提醒", options: [])
        let category = UNNotificationCategory(
            identifier: Self.categoryID,
            actions: [complete, restart, snooze],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func schedule(itemName: String, duration: TimeInterval, target: Date) {
        let content = UNMutableNotificationContent()
        content.title = "制造完成"
        content.body = "「\(itemName)」已经到时间了"
        content.sound = .default
        content.categoryIdentifier = Self.categoryID
        content.userInfo = ["itemName": itemName, "duration": duration]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: target)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "craft-timer", content: content, trigger: trigger)

        cancel()
        UNUserNotificationCenter.current().add(request)
    }

    func cancel() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["craft-timer"])
        center.removeDeliveredNotifications(withIdentifiers: ["craft-timer"])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let info = response.notification.request.content.userInfo
        let itemName = info["itemName"] as? String ?? "制造"
        let duration = info["duration"] as? TimeInterval ?? 0
        let action = response.actionIdentifier

        Task { @MainActor in
            switch action {
            case Self.actionComplete:
                AppStore.shared.completeTimer()
            case Self.actionRestart:
                AppStore.shared.completeAndRestart()
            case Self.actionSnooze:
                AppStore.shared.snoozeTimer()
            default:
                break
            }
            completionHandler()
        }
    }
}
