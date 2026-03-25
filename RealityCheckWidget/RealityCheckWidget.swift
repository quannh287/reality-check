// RealityCheckWidget/RealityCheckWidget.swift
import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Entry

struct RealityCheckEntry: TimelineEntry {
    let date: Date
    let displayValue: String
    let title: String           // card title for medium widget
    let unit: String
    let contextLine: String
    let hasCard: Bool
    let formula: FormulaType?   // for accent color
    let cardType: CardType      // manual vs formula
    let progressValue: Double?  // 0.0–1.0 for formula progress bar in medium widget
}

// MARK: - Provider (unchanged logic)

struct RealityCheckProvider: TimelineProvider {
    private var modelContext: ModelContext {
        let container = try! ModelContainer(
            for: RealityCard.self,
            configurations: AppGroupContainer.modelConfiguration
        )
        return ModelContext(container)
    }

    func placeholder(in context: Context) -> RealityCheckEntry {
        RealityCheckEntry(date: Date(), displayValue: "47", title: "Runway",
                          unit: "ngày", contextLine: "runway nếu nghỉ việc hôm nay",
                          hasCard: true, formula: .countdown, cardType: .formula,
                          progressValue: 0.65)
    }

    func getSnapshot(in context: Context, completion: @escaping (RealityCheckEntry) -> Void) {
        completion(fetchEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RealityCheckEntry>) -> Void) {
        let entry = fetchEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func fetchEntry() -> RealityCheckEntry {
        let descriptor = FetchDescriptor<RealityCard>(predicate: #Predicate { $0.isPinned == true })
        guard let card = try? modelContext.fetch(descriptor).first else {
            return RealityCheckEntry(date: Date(), displayValue: "--", title: "",
                                     unit: "", contextLine: "Mở app để tạo Reality Card đầu tiên",
                                     hasCard: false, formula: nil, cardType: .manual,
                                     progressValue: nil)
        }
        // Compute optional progress for formula cards (0.0–1.0)
        let progress: Double? = {
            guard card.type == .formula, let formula = card.formula else { return nil }
            switch formula {
            case .countdown:
                guard let target = card.targetDate else { return nil }
                let total = target.timeIntervalSince(card.createdAt)
                let elapsed = Date().timeIntervalSince(card.createdAt)
                guard total > 0 else { return nil }
                return min(1.0, max(0.0, elapsed / total))
            case .divide, .count, .subtract:
                guard let a = card.inputA, let b = card.inputB, b > 0 else { return nil }
                return min(1.0, a / b)
            }
        }()
        return RealityCheckEntry(
            date: Date(),
            displayValue: FormulaEngine.displayValue(for: card),
            title: card.title,
            unit: card.unit,
            contextLine: card.contextLine,
            hasCard: true,
            formula: card.formula,
            cardType: card.type,
            progressValue: progress
        )
    }
}

// MARK: - Widget accent color helper

extension RealityCheckEntry {
    var accentColor: Color {
        guard hasCard else { return Color(hex: "#ff6b6b") }
        if cardType == .manual { return Color(hex: "#ff6b6b") }
        switch formula {
        case .countdown: return Color(hex: "#00f5a0")
        case .divide:    return Color(hex: "#64dfdf")
        case .count:     return Color(hex: "#c77dff")
        case .subtract:  return Color(hex: "#ffd93d")
        case .none:      return Color(hex: "#ff6b6b")
        }
    }
}

// MARK: - Small widget view

struct WidgetSmallView: View {
    let entry: RealityCheckEntry

    var body: some View {
        ZStack {
            // Static orb (no animation in widget)
            Circle()
                .fill(entry.accentColor.opacity(0.20))
                .frame(width: 100, height: 100)
                .blur(radius: 30)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: 10, y: -10)

            if entry.hasCard {
                VStack(spacing: 2) {
                    Text(entry.displayValue)
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundStyle(entry.accentColor)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text(entry.unit.uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .tracking(1)
                    Text(entry.contextLine)
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 10)
                        .padding(.top, 3)
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
}

// MARK: - Medium widget view

struct WidgetMediumView: View {
    let entry: RealityCheckEntry

    var body: some View {
        HStack(spacing: 0) {
            // Left: big value
            VStack(spacing: 4) {
                Text(entry.displayValue)
                    .font(.system(size: 42, weight: .heavy))
                    .foregroundStyle(entry.accentColor)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                Text(entry.unit.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)
            .overlay(
                Rectangle()
                    .frame(width: 1)
                    .foregroundStyle(Color.white.opacity(0.08)),
                alignment: .trailing
            )

            // Right: title + context + progress
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(entry.contextLine)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if let progress = entry.progressValue {
                    ProgressView(value: progress)
                        .tint(entry.accentColor)
                        .padding(.top, 2)
                }
            }
            .padding(.leading, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .overlay(
            Circle()
                .fill(entry.accentColor.opacity(0.15))
                .frame(width: 120)
                .blur(radius: 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .offset(x: -20, y: -20)
        )
    }
}

// MARK: - Entry view dispatcher

struct RealityCheckWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: RealityCheckEntry

    var body: some View {
        switch family {
        case .systemMedium: WidgetMediumView(entry: entry)
        default:            WidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Widget bundle

@main
struct RealityCheckWidgetBundle: Widget {
    let kind = "RealityCheckWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RealityCheckProvider()) { entry in
            RealityCheckWidgetView(entry: entry)
                .containerBackground(
                    LinearGradient(
                        colors: [Color(hex: "#0d1b2a"), Color(hex: "#071a0f")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    for: .widget
                )
        }
        .configurationDisplayName("Reality Check")
        .description("Hiện Reality Card trên home screen")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
