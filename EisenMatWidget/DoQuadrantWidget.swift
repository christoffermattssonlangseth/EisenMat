import WidgetKit
import SwiftUI
import SwiftData

struct DoEntry: TimelineEntry {
    let date: Date
    let tasks: [TaskSnapshot]
}

struct DoProvider: TimelineProvider {
    func placeholder(in context: Context) -> DoEntry {
        DoEntry(date: .now, tasks: samples)
    }

    func getSnapshot(in context: Context, completion: @escaping (DoEntry) -> Void) {
        completion(DoEntry(date: .now, tasks: loadTopDo() ?? samples))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DoEntry>) -> Void) {
        let entry = DoEntry(date: .now, tasks: loadTopDo() ?? [])
        let next = Date().addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private var samples: [TaskSnapshot] {
        [
            TaskSnapshot(id: UUID(), title: "Example urgent + important", dueDate: nil, urgency: 0.9, importance: 0.9),
            TaskSnapshot(id: UUID(), title: "Another important task",     dueDate: nil, urgency: 0.7, importance: 0.8),
        ]
    }

    private func loadTopDo() -> [TaskSnapshot]? {
        guard let container = try? SharedModelContainer.make() else { return nil }
        let ctx = ModelContext(container)
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate {
                !$0.isCompleted && !$0.isArchived && !$0.isInInbox
                    && $0.urgency >= 0.5 && $0.importance >= 0.5
            }
        )
        guard let items = try? ctx.fetch(descriptor) else { return nil }
        let sorted = items.sorted { a, b in
            switch (a.dueDate, b.dueDate) {
            case let (x?, y?): return x < y
            case (_?, nil):    return true
            case (nil, _?):    return false
            default: return (a.urgency + a.importance) > (b.urgency + b.importance)
            }
        }
        return sorted.prefix(5).map {
            TaskSnapshot(id: $0.id, title: $0.title, dueDate: $0.dueDate,
                         urgency: $0.urgency, importance: $0.importance)
        }
    }
}

struct DoQuadrantWidget: Widget {
    let kind = "DoQuadrantWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DoProvider()) { entry in
            DoQuadrantWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Do quadrant")
        .description("Your top urgent + important tasks.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct EisenMatWidgetBundle: WidgetBundle {
    var body: some Widget {
        DoQuadrantWidget()
    }
}
