// RealityCheck/ViewModels/CardFormViewModel.swift
import SwiftUI
import SwiftData
import WidgetKit

@Observable
final class CardFormViewModel {
    var title: String = ""
    var type: CardType = .manual
    var value: String = ""
    var formula: FormulaType = .divide
    var inputA: String = ""
    var inputALabel: String = ""
    var inputB: String = ""
    var inputBLabel: String = ""
    var targetDate: Date = Date()
    var unit: String = ""
    var contextLine: String = ""

    let isEditing: Bool

    init(card: RealityCard? = nil) {
        isEditing = card != nil
        guard let card else { return }
        title = card.title
        type = card.type
        value = card.value.map { String($0) } ?? ""
        formula = card.formula ?? .divide
        inputA = card.inputA.map { String($0) } ?? ""
        inputALabel = card.inputALabel ?? ""
        inputB = card.inputB.map { String($0) } ?? ""
        inputBLabel = card.inputBLabel ?? ""
        targetDate = card.targetDate ?? Date()
        unit = card.unit
        contextLine = card.contextLine
    }

    // MARK: - Computed

    var canSave: Bool {
        !title.isEmpty && !unit.isEmpty && !contextLine.isEmpty
    }

    var previewDisplayValue: String {
        switch type {
        case .manual:
            guard let v = Double(value) else { return "--" }
            return FormulaEngine.formatNumber(v)
        case .formula:
            switch formula {
            case .divide:
                guard let a = Double(inputA), let b = Double(inputB) else { return "--" }
                if b == 0 { return "∞" }
                return FormulaEngine.formatNumber(a / b)
            case .count:
                guard let a = Double(inputA), let b = Double(inputB) else { return "--" }
                return "\(Int(a))/\(Int(b))"
            case .subtract:
                guard let a = Double(inputA), let b = Double(inputB) else { return "--" }
                return FormulaEngine.formatNumber(a - b)
            case .countdown:
                let days = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
                return "\(max(0, days))"
            }
        }
    }

    var previewAccentColor: Color {
        switch type {
        case .manual: return .auroraRed
        case .formula: return formula.accentColor
        }
    }

    // MARK: - Actions

    func save(card: RealityCard?, context: ModelContext, dismiss: DismissAction) {
        if let card {
            card.title = title
            card.type = type
            card.value = Double(value)
            card.formula = type == .formula ? formula : nil
            card.inputA = Double(inputA)
            card.inputALabel = inputALabel.isEmpty ? nil : inputALabel
            card.inputB = Double(inputB)
            card.inputBLabel = inputBLabel.isEmpty ? nil : inputBLabel
            card.targetDate = formula == .countdown ? targetDate : nil
            card.unit = unit
            card.contextLine = contextLine
            card.updatedAt = Date()
        } else {
            let newCard = RealityCard(
                title: title,
                type: type,
                formula: type == .formula ? formula : nil,
                value: Double(value),
                inputA: Double(inputA),
                inputALabel: inputALabel.isEmpty ? nil : inputALabel,
                inputB: Double(inputB),
                inputBLabel: inputBLabel.isEmpty ? nil : inputBLabel,
                targetDate: formula == .countdown ? targetDate : nil,
                unit: unit,
                contextLine: contextLine
            )
            context.insert(newCard)
        }
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }

    func togglePin(_ card: RealityCard, context: ModelContext) {
        let isPinned = card.isPinned
        withAnimation {
            for c in (try? context.fetch(FetchDescriptor<RealityCard>())) ?? [] where c.isPinned {
                c.isPinned = false
            }
            card.isPinned = !isPinned
            card.updatedAt = Date()
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    func delete(_ card: RealityCard, context: ModelContext, dismiss: DismissAction) {
        context.delete(card)
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
