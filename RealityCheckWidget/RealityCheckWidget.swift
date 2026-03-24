import WidgetKit
import SwiftUI
import SwiftData

struct RealityCheckEntry: TimelineEntry {
    let date: Date
    let displayValue: String
    let unit: String
    let contextLine: String
    let hasCard: Bool
}

struct RealityCheckProvider: TimelineProvider {
    private var modelContext: ModelContext {
        let container = try! ModelContainer(
            for: RealityCard.self,
            configurations: AppGroupContainer.modelConfiguration
        )
        return ModelContext(container)
    }

    func placeholder(in context: Context) -> RealityCheckEntry {
        RealityCheckEntry(
            date: Date(),
            displayValue: "47",
            unit: "ngày",
            contextLine: "runway nếu nghỉ việc hôm nay",
            hasCard: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RealityCheckEntry) -> Void) {
        completion(fetchEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RealityCheckEntry>) -> Void) {
        let entry = fetchEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchEntry() -> RealityCheckEntry {
        let descriptor = FetchDescriptor<RealityCard>(
            predicate: #Predicate { $0.isPinned == true }
        )
        guard let card = try? modelContext.fetch(descriptor).first else {
            return RealityCheckEntry(
                date: Date(),
                displayValue: "--",
                unit: "",
                contextLine: "Mở app để tạo Reality Card đầu tiên",
                hasCard: false
            )
        }
        return RealityCheckEntry(
            date: Date(),
            displayValue: FormulaEngine.displayValue(for: card),
            unit: card.unit,
            contextLine: card.contextLine,
            hasCard: true
        )
    }
}

struct RealityCheckWidgetView: View {
    let entry: RealityCheckEntry

    var body: some View {
        if entry.hasCard {
            VStack(spacing: 2) {
                Text(entry.displayValue)
                    .font(.system(size: 42, weight: .heavy))
                    .foregroundStyle(Color(red: 1, green: 0.267, blue: 0.267))
                    .minimumScaleFactor(0.5)
                Text(entry.unit.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                Text(entry.contextLine)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
            .padding(12)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "plus.rectangle.on.rectangle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text(entry.contextLine)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(12)
        }
    }
}

@main
struct RealityCheckWidgetBundle: Widget {
    let kind = "RealityCheckWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RealityCheckProvider()) { entry in
            RealityCheckWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Reality Check")
        .description("Hiện Reality Card trên home screen")
        .supportedFamilies([.systemSmall])
    }
}
