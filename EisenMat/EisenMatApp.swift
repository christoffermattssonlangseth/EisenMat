import SwiftUI
import SwiftData

@main
struct EisenMatApp: App {
    let container: ModelContainer
    let notifications = NotificationScheduler()

    init() {
        do {
            container = try SharedModelContainer.make()
        } catch {
            fatalError("Failed to init ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.notificationScheduler, notifications)
                .task {
                    await notifications.requestAuthorizationIfNeeded()
                }
        }
        .modelContainer(container)
    }
}

private struct NotificationSchedulerKey: EnvironmentKey {
    static let defaultValue: NotificationScheduling = NotificationScheduler()
}

extension EnvironmentValues {
    var notificationScheduler: NotificationScheduling {
        get { self[NotificationSchedulerKey.self] }
        set { self[NotificationSchedulerKey.self] = newValue }
    }
}
