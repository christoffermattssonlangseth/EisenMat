import SwiftUI
import WidgetKit

struct DoQuadrantWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DoEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "bolt.fill").foregroundStyle(.orange)
                Text("Do").font(.caption.weight(.bold))
                Spacer()
            }
            if entry.tasks.isEmpty {
                Text("Nothing urgent & important.")
                    .font(.caption2).foregroundStyle(.secondary)
            } else {
                ForEach(entry.tasks.prefix(family == .systemSmall ? 3 : 5)) { t in
                    HStack(spacing: 4) {
                        Circle().fill(.orange).frame(width: 4, height: 4)
                        Text(t.title)
                            .font(.caption2).lineLimit(1)
                        Spacer(minLength: 0)
                        if let d = t.dueDate {
                            Text(d, style: .date).font(.system(size: 9)).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }
}
