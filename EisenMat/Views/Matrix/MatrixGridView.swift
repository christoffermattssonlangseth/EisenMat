import SwiftUI
import SwiftData

struct MatrixGridView: View {
    @Query private var tasks: [TaskItem]

    var tagFilter: Tag?
    var compact: Bool
    private let cardSize = CGSize(width: 118, height: 50)
    private let dotSize = CGSize(width: 18, height: 18)

    init(tagFilter: Tag?, compact: Bool = false) {
        self.tagFilter = tagFilter
        self.compact = compact
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
            let placed = positionedTasks(in: geo.size)
            ZStack(alignment: .topLeading) {
                quadrantTiles(in: geo.size)
                axisLabels(in: geo.size)
                ForEach(placed, id: \.task.id) { entry in
                    Group {
                        if compact {
                            TaskDot(task: entry.task)
                                .frame(width: dotSize.width, height: dotSize.height)
                        } else {
                            TaskCard(task: entry.task)
                                .frame(width: cardSize.width, height: cardSize.height)
                        }
                    }
                    .position(x: entry.point.x, y: entry.point.y)
                    .zIndex(Double(entry.stackIndex))
                    .transition(.scale.combined(with: .opacity))
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

    private struct PlacedTask {
        let task: TaskItem
        let point: CGPoint
        let stackIndex: Int
    }

    private func positionedTasks(in size: CGSize) -> [PlacedTask] {
        // Bucket tasks by 1%-rounded (urgency, importance) so visually-coincident
        // ones get fanned out instead of stacking on the same pixel.
        struct Bucket: Hashable { let u: Int; let i: Int }
        var groups: [Bucket: [TaskItem]] = [:]
        for t in tasks {
            let key = Bucket(u: Int((t.urgency * 100).rounded()),
                             i: Int((t.importance * 100).rounded()))
            groups[key, default: []].append(t)
        }
        // Stable order within bucket: oldest first → newest on top.
        for k in groups.keys {
            groups[k]?.sort { $0.createdAt < $1.createdAt }
        }

        let step: CGFloat = compact ? 6 : 10
        var result: [PlacedTask] = []
        result.reserveCapacity(tasks.count)
        for t in tasks {
            let key = Bucket(u: Int((t.urgency * 100).rounded()),
                             i: Int((t.importance * 100).rounded()))
            let bucket = groups[key] ?? [t]
            let n = bucket.count
            let idx = bucket.firstIndex(where: { $0.id == t.id }) ?? 0
            let centered = CGFloat(idx) - CGFloat(n - 1) / 2
            let baseX = clampedX(t.urgency * size.width, width: size.width)
            let baseY = clampedY(t.importance, height: size.height)
            let p = CGPoint(x: baseX + centered * step,
                            y: baseY + centered * step)
            result.append(PlacedTask(task: t, point: p, stackIndex: idx))
        }
        return result
    }

    private var halfX: CGFloat { (compact ? dotSize.width : cardSize.width) / 2 }
    private var halfY: CGFloat { (compact ? dotSize.height : cardSize.height) / 2 }

    private func clampedX(_ x: Double, width: Double) -> Double {
        max(halfX + 6, min(width - halfX - 6, x))
    }
    private func clampedY(_ importance: Double, height: Double) -> Double {
        let raw = (1 - importance) * height
        let topMargin: CGFloat = compact ? 12 : 28
        return max(halfY + topMargin, min(height - halfY - 6, raw))
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
