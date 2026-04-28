import XCTest
@testable import EisenMat

final class QuadrantTests: XCTestCase {
    func testQuadrantBoundaries() {
        let cases: [(Double, Double, Quadrant)] = [
            (0.0, 0.0, .delete),
            (0.0, 1.0, .schedule),
            (1.0, 1.0, .doIt),
            (1.0, 0.0, .delegate),
            (0.5, 0.5, .doIt),       // tie goes to upper/right
            (0.49, 0.51, .schedule),
            (0.51, 0.49, .delegate),
            (0.49, 0.49, .delete),
        ]
        for (u, i, expected) in cases {
            XCTAssertEqual(Quadrant.from(urgency: u, importance: i), expected,
                           "u=\(u) i=\(i)")
        }
    }

    func testTaskItemQuadrantMatchesStatic() {
        let t = TaskItem(title: "x", urgency: 0.8, importance: 0.9)
        XCTAssertEqual(t.quadrant, .doIt)
        t.urgency = 0.1
        XCTAssertEqual(t.quadrant, .schedule)
    }
}
