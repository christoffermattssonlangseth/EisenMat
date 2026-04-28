import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Environment(\.modelContext) private var context
    @Query(
        filter: #Predicate<TaskItem> { $0.isArchived },
        sort: \.createdAt,
        order: .reverse
    )
    private var items: [TaskItem]

    var body: some View {
        NavigationStack {
            List {
                if items.isEmpty {
                    Text("Archive is empty.")
                        .foregroundStyle(.secondary)
                }
                ForEach(items) { t in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(t.title)
                            Text(t.quadrant.title).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Restore") {
                            t.isArchived = false
                            try? context.save()
                        }.buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle("Archive")
        }
    }
}
