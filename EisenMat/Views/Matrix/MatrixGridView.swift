import SwiftUI
import SwiftData

struct MatrixGridView: View {
    @Query private var tasks: [TaskItem]

    var tagFilter: Tag?
    private let cardSize = CGSize(width: 118, height: 50)

    init(tagFilter: Tag?) {
        self.tagFilter = tagFilter
        if let tagID = tagFilter?.id {
            _tasks = Query(
                filter: #Predicate<TaskItem> { t in
                    !t.isCompleted && !t.isArchived &&
                    t.tags.contains(where: { $0.id == tagID })
                },
                sort: \.createdAt
            )
        } else {
            _tasks = Query(
                filter: #Predicate<TaskItem> { t in
                    !t.isCompleted && !t.isArchived
                },
                sort: \.createdAt
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                quadrantTiles(in: geo.size)
                axisLabels(in: geo.size)
                ForEach(tasks) { task in
                    TaskCard(task: task)
                        .frame(width: cardSize.width, height: cardSize.height)
                        .position(
                            x: clampedX(task.urgency * geo.size.width, width: geo.size.width),
                            y: clampedY(task.importance, height: geo.size.height)
                        )
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 6)
    }

    private func clampedX(_ x: Double, width: Double) -> Double {
        max(cardSize.width / 2 + 6, min(width - cardSize.width / 2 - 6, x))
    }
    private func clampedY(_ importance: Double, height: Double) -> Double {
        let raw = (1 - importance) * height
        return max(cardSize.height / 2 + 28, min(height - cardSize.height / 2 - 6, raw))
    }

    @ViewBuilder
    private func quadrantTiles(in size: CGSize) -> some View {
        let w = size.width / 2
        let h = size.height / 2
        ZStack(alignment: .topLeading) {
            tile(.schedule).frame(width: w, height: h).offset(x: 0, y: 0)
            tile(.doIt)    .frame(width: w, height: h).offset(x: w, y: 0)
            tile(.delete)  .frame(width: w, height: h).offset(x: 0, y: h)
            tile(.delegate).frame(width: w, height: h).offset(x: w, y: h)
        }
    }

    private func tile(_ q: Quadrant) -> some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [q.tint.opacity(0.22), q.tint.opacity(0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: q.symbol)
                        .font(.caption.weight(.bold))
                    Text(q.title.uppercased())
                        .font(.caption.weight(.heavy))
                        .tracking(1.2)
                }
                .foregroundStyle(q.tint)
                Text(q.subtitle)
                    .font(.system(size: 9))
                    .foregroundStyle(q.tint.opacity(0.7))
            }
            .padding(10)
        }
        .overlay(
            Rectangle()
                .stroke(Color.primary.opacity(0.05), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private func axisLabels(in size: CGSize) -> some View {
        Text("urgent →")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.secondary)
            .position(x: size.width - 32, y: size.height - 8)
        Text("important ↑")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.secondary)
            .rotationEffect(.degrees(-90))
            .position(x: 12, y: size.height / 2)
    }
}
