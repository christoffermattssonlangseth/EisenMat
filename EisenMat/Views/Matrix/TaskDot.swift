import SwiftUI
import SwiftData
import WidgetKit

struct TaskDot: View {
    @Environment(\.modelContext) private var context
    @Environment(\.notificationScheduler) private var notifications
    @Bindable var task: TaskItem

    @State private var showPreview = false
    @State private var showDetail = false
    @State private var hovering = false

    private var quadrant: Quadrant { task.quadrant }

    var body: some View {
        Circle()
            .fill(task.isCompleted ? Color.secondary.opacity(0.45) : quadrant.tint)
            .overlay(
                Circle().stroke(Color.white.opacity(0.85), lineWidth: 1)
            )
            .overlay(
                Group {
                    if task.dueDate != nil {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 5, height: 5)
                            .offset(x: 6, y: -6)
                    }
                }
            )
            .shadow(color: Color.black.opacity(0.18), radius: 2, x: 0, y: 1)
            .scaleEffect(hovering || showPreview ? 1.55 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: hovering)
            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: showPreview)
            .contentShape(Circle().inset(by: -8))
            .onHover { isHovering in
                hovering = isHovering
                showPreview = isHovering
            }
            .onTapGesture { showDetail = true }
            .onLongPressGesture(minimumDuration: 0.3) {
                showPreview = true
            }
            .popover(isPresented: $showPreview, arrowEdge: .top) {
                preview
                    .presentationCompactAdaptation(.popover)
            }
            .sheet(isPresented: $showDetail) {
                TaskDetailSheet(task: task)
            }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: quadrant.symbol)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(quadrant.tint, in: RoundedRectangle(cornerRadius: 6))
                Text(quadrant.title.uppercased())
                    .font(.caption.weight(.heavy))
                    .tracking(1.0)
                    .foregroundStyle(quadrant.tint)
                Spacer()
            }
            Text(task.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(3)
                .strikethrough(task.isCompleted)
            if !task.tags.isEmpty || task.dueDate != nil {
                HStack(spacing: 6) {
                    ForEach(task.tags) { tag in
                        HStack(spacing: 3) {
                            Circle().fill(tag.color).frame(width: 6, height: 6)
                            Text(tag.name).font(.caption2)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(tag.color.opacity(0.12), in: Capsule())
                    }
                    if let d = task.dueDate {
                        Label {
                            Text(d, style: .date).font(.caption2)
                        } icon: {
                            Image(systemName: "calendar").font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            Toggle(isOn: Binding(
                get: { task.isCompleted },
                set: { newValue in
                    if newValue != task.isCompleted { toggleCompleted() }
                }
            )) {
                HStack(spacing: 6) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    Text(task.isCompleted ? "Done" : "Mark as done")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .toggleStyle(.button)
            .tint(quadrant.tint)
            .controlSize(.regular)

            HStack {
                Button("Open details") {
                    showPreview = false
                    showDetail = true
                }
                .buttonStyle(.bordered)
                .tint(quadrant.tint)
                .controlSize(.small)
                Spacer()
            }
        }
        .padding(14)
        .frame(minWidth: 240, maxWidth: 300)
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
