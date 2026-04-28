import SwiftUI
import SwiftData

struct MatrixView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Tag> { _ in true }) private var tags: [Tag]
    @State private var activeTagFilter: Tag?
    @State private var showTagManager = false
    @State private var showNewTaskSheet = false

    var body: some View {
        NavigationStack {
            MatrixGridView(tagFilter: activeTagFilter)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .navigationTitle("EisenMat")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Button {
                                activeTagFilter = nil
                            } label: {
                                Label("All tasks", systemImage: activeTagFilter == nil ? "checkmark" : "")
                            }
                            ForEach(tags) { tag in
                                Button {
                                    activeTagFilter = tag
                                } label: {
                                    HStack {
                                        Circle().fill(tag.color).frame(width: 10, height: 10)
                                        Text(tag.name)
                                        if activeTagFilter?.id == tag.id {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                            Divider()
                            Button("Manage tags…") { showTagManager = true }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showNewTaskSheet = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showTagManager) { TagManagerView() }
                .sheet(isPresented: $showNewTaskSheet) {
                    NewTaskSheet(isPresented: $showNewTaskSheet)
                }
        }
    }
}

private struct NewTaskSheet: View {
    @Environment(\.modelContext) private var context
    @Binding var isPresented: Bool
    @State private var title = ""
    @State private var urgency: Double = 0.5
    @State private var importance: Double = 0.5

    private var derivedQuadrant: Quadrant {
        Quadrant.from(urgency: urgency, importance: importance)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                }
                Section("Urgency") {
                    HStack {
                        Text("not urgent").font(.caption2).foregroundStyle(.secondary)
                        Slider(value: $urgency, in: 0...1)
                        Text("urgent").font(.caption2).foregroundStyle(.secondary)
                    }
                    Text(String(format: "%.2f", urgency))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Importance") {
                    HStack {
                        Text("low").font(.caption2).foregroundStyle(.secondary)
                        Slider(value: $importance, in: 0...1)
                        Text("high").font(.caption2).foregroundStyle(.secondary)
                    }
                    Text(String(format: "%.2f", importance))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section {
                    LabeledContent("Quadrant") {
                        Text(derivedQuadrant.title)
                            .font(.headline)
                            .foregroundStyle(quadrantColor(derivedQuadrant))
                    }
                }
            }
            .navigationTitle("New task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        let t = TaskItem(
                            title: trimmed,
                            urgency: urgency,
                            importance: importance,
                            isInInbox: false
                        )
                        context.insert(t)
                        try? context.save()
                        isPresented = false
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func quadrantColor(_ q: Quadrant) -> Color {
        switch q {
        case .doIt:     .orange
        case .schedule: .blue
        case .delegate: .purple
        case .delete:   .gray
        }
    }
}
