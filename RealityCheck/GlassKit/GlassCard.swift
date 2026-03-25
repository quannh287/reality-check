// RealityCheck/GlassKit/GlassCard.swift
import SwiftUI

enum GlassCardStyle {
    case pinned
    case unpinned
}

struct GlassCard: View {
    let card: RealityCard
    var style: GlassCardStyle = .unpinned

    private var accentColor: Color {
        switch card.type {
        case .manual: return .auroraRed
        case .formula: return card.formula?.accentColor ?? .auroraRed
        }
    }

    private var displayValue: String {
        FormulaEngine.displayValue(for: card)
    }

    // Progress ratio for formula cards (0.0–1.0), nil if not applicable
    private var progressValue: Double? {
        guard card.type == .formula, card.formula == .divide else { return nil }
        guard let a = card.inputA, let b = card.inputB, b != 0 else { return nil }
        return min(max(a / b, 0), 1)
    }

    var body: some View {
        switch style {
        case .pinned:  pinnedView
        case .unpinned: unpinnedView
        }
    }

    // MARK: Pinned (hero)
    private var pinnedView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.title)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(accentColor.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(1)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(displayValue)
                            .font(.system(size: 38, weight: .heavy))
                            .foregroundStyle(accentColor)
                            .minimumScaleFactor(0.6)
                        Text(card.unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(card.contextLine)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Text(card.type.rawValue)
                    .font(.system(size: 8, weight: .semibold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(accentColor.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(accentColor.opacity(0.28), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .foregroundStyle(accentColor.opacity(0.8))
            }

            if let progress = progressValue {
                ProgressView(value: progress)
                    .tint(
                        LinearGradient(
                            colors: [.auroraRed, Color(hex: "#ff9f43"), .auroraYellow],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .scaleEffect(y: 1.5)
            }
        }
        .padding(16)
        .glassCard(accent: accentColor, accentOpacity: 0.22)
        .overlay(ShimmerView().clipShape(RoundedRectangle(cornerRadius: 16)))
    }

    // MARK: Unpinned (compact)
    private var unpinnedView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(card.title)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(displayValue)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(accentColor)
                    Text(card.unit)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassCard(accent: accentColor, accentOpacity: 0.12)
        .overlay(ShimmerView().clipShape(RoundedRectangle(cornerRadius: 16)))
    }
}
