import SwiftUI
import SwiftData
import WidgetKit

struct TaskDetailSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.notificationScheduler) private var notifications
    @Bindable var task: TaskItem
    @Query(sort: \Tag.name) private var allTags: [Tag]
    @State private var useDueDate: Bool
    @State private var draftDueDate: Date

    init(task: TaskItem) {
        self.task = task
        _useDueDate = State(initialValue: task.dueDate != nil)
        _draftDueDate = State(initialValue: task.dueDate ?? .now.addingTimeInterval(3600))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $task.title)
                    TextField("Notes", text: Binding(
                        get: { task.notes ?? "" },
                        set: { task.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                }

                Section("Due date") {
                    Toggle("Set due date", isOn: $useDueDate)
                    if useDueDate {
                        DatePicker("Due", selection: $draftDueDate)
                    }
                }

                Section("Tags") {
                    if allTags.isEmpty {
                        Text("No tags yet. Create one from the Matrix screen.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    ForEach(allTags) { tag in
                        let on = task.tags.contains(where: { $0.id == tag.id })
                        Button {
                            if on {
                                task.tags.removeAll { $0.id == tag.id }
                            } else {
                                task.tags.append(tag)
                            }
                        } label: {
                            HStack {
                                Circle().fill(tag.color).frame(width: 10, height: 10)
                                Text(tag.name)
                                Spacer()
                                if on { Image(systemName: "checkmark") }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section("Urgency") {
                    HStack {
                        Text("not urgent").font(.caption2).foregroundStyle(.secondary)
                        Slider(value: $task.urgency, in: 0...1)
                        Text("urgent").font(.caption2).foregroundStyle(.secondary)
                    }
                    Text(String(format: "%.2f", task.urgency))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Importance") {
                    HStack {
                        Text("low").font(.caption2).foregroundStyle(.secondary)
                        Slider(value: $task.importance, in: 0...1)
                        Text("high").font(.caption2).foregroundStyle(.secondary)
                    }
                    Text(String(format: "%.2f", task.importance))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section {
                    LabeledContent("Quadrant", value: task.quadrant.title)
                }

                Section {
                    Button(task.isArchived ? "Restore from archive" : "Archive") {
                        task.isArchived.toggle()
                        notifications.cancel(taskID: task.id)
                        saveAndClose()
                    }
                    Button("Delete permanently", role: .destructive) {
                        notifications.cancel(taskID: task.id)
                        context.delete(task)
                        saveAndClose()
                    }
                }
            }
            .navigationTitle("Task")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { saveAndClose() }
                }
            }
        }
    }

    private func saveAndClose() {
        task.dueDate = useDueDate ? draftDueDate : nil
        try? context.save()
        Task {
            await notifications.schedule(taskID: task.id, title: task.title, dueDate: task.dueDate)
        }
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
