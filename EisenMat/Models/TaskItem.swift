import Foundation
import SwiftData

@Model
final class TaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String?
    var urgency: Double
    var importance: Double
    var dueDate: Date?
    var isCompleted: Bool
    var isArchived: Bool
    var isInInbox: Bool
    var createdAt: Date
    var completedAt: Date?

    @Relationship(inverse: \Tag.tasks) var tags: [Tag]

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        urgency: Double = 0.5,
        importance: Double = 0.5,
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        isArchived: Bool = false,
        isInInbox: Bool = false,
        createdAt: Date = .now,
        completedAt: Date? = nil,
        tags: [Tag] = []
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.urgency = urgency
        self.importance = importance
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.isArchived = isArchived
        self.isInInbox = isInInbox
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.tags = tags
    }

    var quadrant: Quadrant {
        .from(urgency: urgency, importance: importance)
    }

    var isActive: Bool {
        !isCompleted && !isArchived && !isInInbox
    }
}
