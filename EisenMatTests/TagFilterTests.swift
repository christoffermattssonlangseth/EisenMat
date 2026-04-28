import XCTest
import SwiftData
@testable import EisenMat

final class TagFilterTests: XCTestCase {
    var container: ModelContainer!
    var ctx: ModelContext!

    override func setUpWithError() throws {
        container = try SharedModelContainer.make(inMemory: true)
        ctx = ModelContext(container)
    }

    func testFilterByTag() throws {
        let work = Tag(name: "Work", colorHex: "#FF0000")
        let home = Tag(name: "Home", colorHex: "#00FF00")
        ctx.insert(work); ctx.insert(home)

        let t1 = TaskItem(title: "A", urgency: 0.9, importance: 0.9, isInInbox: false, tags: [work])
        let t2 = TaskItem(title: "B", urgency: 0.9, importance: 0.9, isInInbox: false, tags: [home])
        let t3 = TaskItem(title: "C", urgency: 0.9, importance: 0.9, isInInbox: false, tags: [work, home])
        ctx.insert(t1); ctx.insert(t2); ctx.insert(t3)
        try ctx.save()

        let all = try ctx.fetch(FetchDescriptor<TaskItem>())
        XCTAssertEqual(all.count, 3)

        let workID = work.id
        let workTasks = all.filter { $0.tags.contains(where: { $0.id == workID }) }
        XCTAssertEqual(Set(workTasks.map { $0.title }), ["A", "C"])

        let homeID = home.id
        let homeTasks = all.filter { $0.tags.contains(where: { $0.id == homeID }) }
        XCTAssertEqual(Set(homeTasks.map { $0.title }), ["B", "C"])
    }

    func testActiveTaskFlag() {
        let t = TaskItem(title: "x", isInInbox: true)
        XCTAssertFalse(t.isActive)
        t.isInInbox = false
        XCTAssertTrue(t.isActive)
        t.isCompleted = true
        XCTAssertFalse(t.isActive)
    }
}
