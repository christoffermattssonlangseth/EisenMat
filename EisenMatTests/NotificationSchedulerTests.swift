import XCTest
import UserNotifications
@testable import EisenMat

final class FakeNotificationCenter: NotificationCenterProtocol {
    var scheduled: [UNNotificationRequest] = []
    var authRequested = false

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        authRequested = true
        return true
    }
    func add(_ request: UNNotificationRequest) async throws {
        scheduled.append(request)
    }
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        scheduled.removeAll { identifiers.contains($0.identifier) }
    }
    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        scheduled
    }
}

final class NotificationSchedulerTests: XCTestCase {
    func makeScheduler() -> (NotificationScheduler, FakeNotificationCenter, UserDefaults) {
        let center = FakeNotificationCenter()
        let suiteName = "test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let sched = NotificationScheduler(center: center, defaults: defaults)
        return (sched, center, defaults)
    }

    func testAuthorizationAskedOnce() async {
        let (sched, center, _) = makeScheduler()
        await sched.requestAuthorizationIfNeeded()
        XCTAssertTrue(center.authRequested)
        center.authRequested = false
        await sched.requestAuthorizationIfNeeded()
        XCTAssertFalse(center.authRequested)
    }

    func testScheduleFutureDate() async {
        let (sched, center, _) = makeScheduler()
        let id = UUID()
        await sched.schedule(taskID: id, title: "Bug", dueDate: .now.addingTimeInterval(3600))
        XCTAssertEqual(center.scheduled.count, 1)
        XCTAssertEqual(center.scheduled.first?.identifier, id.uuidString)
    }

    func testScheduleSkipsPastDate() async {
        let (sched, center, _) = makeScheduler()
        await sched.schedule(taskID: UUID(), title: "Old",
                             dueDate: .now.addingTimeInterval(-60))
        XCTAssertTrue(center.scheduled.isEmpty)
    }

    func testScheduleReplacesExisting() async {
        let (sched, center, _) = makeScheduler()
        let id = UUID()
        await sched.schedule(taskID: id, title: "v1", dueDate: .now.addingTimeInterval(3600))
        await sched.schedule(taskID: id, title: "v2", dueDate: .now.addingTimeInterval(7200))
        XCTAssertEqual(center.scheduled.count, 1)
        XCTAssertEqual(center.scheduled.first?.content.title, "v2")
    }

    func testCancelRemoves() async {
        let (sched, center, _) = makeScheduler()
        let id = UUID()
        await sched.schedule(taskID: id, title: "x", dueDate: .now.addingTimeInterval(3600))
        sched.cancel(taskID: id)
        XCTAssertTrue(center.scheduled.isEmpty)
    }
}
