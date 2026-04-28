import SwiftUI
import SwiftData
import WidgetKit

struct TaskCard: View {
    @Environment(\.modelContext) private var context
    @Environment(\.notificationScheduler) private var notifications
    @Bindable var task: TaskItem
    @State private var showDetail = false

    private var quadrant: Quadrant { task.quadrant }

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(quadrant.tint)
                .frame(width: 3)

            Button {
                toggleCompleted()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(task.isCompleted ? quadrant.tint : Color.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
            .padding(.leading, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(2)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? Color.secondary : Color.primary)
                if !task.tags.isEmpty || task.dueDate != nil {
                    HStack(spacing: 4) {
                        ForEach(task.tags.prefix(2)) { tag in
                            Circle().fill(tag.color).frame(width: 6, height: 6)
                        }
                        if task.tags.count > 2 {
                            Text("+\(task.tags.count - 2)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        if let d = task.dueDate {
                            Text(d, style: .date)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.trailing, 8)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(quadrant.tint.opacity(0.25), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture { showDetail = true }
        .sheet(isPresented: $showDetail) {
            TaskDetailSheet(task: task)
        }
    }

    private func toggleCompleted() {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? .now : nil
        if task.isCompleted {
            notifications.cancel(taskID: task.id)
        } else if let due = task.dueDate {
            Task {
                await notifications.schedule(taskID: task.id, title: task.title, dueDate: due)
            }
        }
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
