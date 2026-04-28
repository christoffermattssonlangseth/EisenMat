import Foundation

struct TaskSnapshot: Identifiable, Hashable {
    let id: UUID
    let title: String
    let dueDate: Date?
    let urgency: Double
    let importance: Double
}
