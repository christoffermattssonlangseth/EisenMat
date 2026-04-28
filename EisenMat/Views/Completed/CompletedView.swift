import SwiftUI
import SwiftData

struct CompletedView: View {
    @Environment(\.modelContext) private var context
    @Query(
        filter: #Predicate<TaskItem> { $0.isCompleted },
        sort: \.completedAt,
        order: .reverse
    )
    private var items: [TaskItem]

    var body: some View {
        NavigationStack {
            List {
                if items.isEmpty {
                    Text("Nothing completed yet.")
                        .foregroundStyle(.secondary)
                }
                ForEach(items) { t in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(t.title).strikethrough()
                            HStack {
                                Text(t.quadrant.title)
                                if let d = t.completedAt {
                                    Text("·")
                                    Text(d, style: .date)
                                }
                            }
                            .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Undo") {
                            t.isCompleted = false
                            t.completedAt = nil
                            try? context.save()
                        }.buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle("Completed")
        }
    }
}
