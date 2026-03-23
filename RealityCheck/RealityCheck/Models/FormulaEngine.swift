// RealityCheck/Models/FormulaEngine.swift
import Foundation

enum FormulaEngine {

    static func displayValue(for card: RealityCard) -> String {
        switch card.type {
        case .manual:
            guard let value = card.value else { return "--" }
            return formatNumber(value)

        case .formula:
            guard let formula = card.formula else { return "--" }
            return computeFormula(formula, card: card)
        }
    }

    private static func computeFormula(_ formula: FormulaType, card: RealityCard) -> String {
        switch formula {
        case .divide:
            guard let a = card.inputA, let b = card.inputB else { return "--" }
            if b == 0 { return "∞" }
            return formatNumber(a / b)

        case .count:
            guard let a = card.inputA, let b = card.inputB else { return "--" }
            return "\(Int(a))/\(Int(b))"

        case .subtract:
            guard let a = card.inputA, let b = card.inputB else { return "--" }
            return formatNumber(a - b)

        case .countdown:
            guard let target = card.targetDate else { return "--" }
            let days = Calendar.current.dateComponents([.day], from: Date(), to: target).day ?? 0
            return "\(max(0, days))"
        }
    }

    static func formatNumber(_ value: Double) -> String {
        if value == value.rounded() && abs(value) < 1_000_000_000 {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }
}
