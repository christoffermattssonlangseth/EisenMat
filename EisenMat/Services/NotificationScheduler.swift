import Foundation
import UserNotifications

protocol NotificationCenterProtocol {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func pendingNotificationRequests() async -> [UNNotificationRequest]
}

extension UNUserNotificationCenter: NotificationCenterProtocol {}

protocol NotificationScheduling {
    func requestAuthorizationIfNeeded() async
    func schedule(taskID: UUID, title: String, dueDate: Date?) async
    func cancel(taskID: UUID)
}

final class NotificationScheduler: NotificationScheduling {
    private let center: NotificationCenterProtocol
    private let defaults: UserDefaults
    private let askedKey = "EisenMat.didAskNotificationAuth"

    init(
        center: NotificationCenterProtocol = UNUserNotificationCenter.current(),
        defaults: UserDefaults = .standard
    ) {
        self.center = center
        self.defaults = defaults
    }

    func requestAuthorizationIfNeeded() async {
        guard !defaults.bool(forKey: askedKey) else { return }
        defaults.set(true, forKey: askedKey)
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func schedule(taskID: UUID, title: String, dueDate: Date?) async {
        cancel(taskID: taskID)
        guard let dueDate, dueDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.sound = .default

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: dueDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: taskID.uuidString,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    func cancel(taskID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [taskID.uuidString])
    }
}
