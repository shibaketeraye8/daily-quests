import Foundation
import UserNotifications

/// Локальные уведомления: одно ежедневное напоминание по расписанию.
enum Reminder {
    static let identifier = "daily-quests-reminder"

    static func requestPermission(_ completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    static func schedule(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Квесты дня"
        content.body = "⚔️ Герой, тебя ждут ежедневные квесты. Не теряй стрик!"
        content.sound = .default

        var components = DateComponents()
        components.hour = max(0, min(23, hour))
        components.minute = max(0, min(59, minute))

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request) { _ in }
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    static func isScheduled(_ completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let scheduled = requests.contains { $0.identifier == identifier }
            DispatchQueue.main.async {
                completion(scheduled)
            }
        }
    }

    static func isAuthorized(_ completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let ok = settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral
            DispatchQueue.main.async {
                completion(ok)
            }
        }
    }
}
