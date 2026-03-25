// RealityCheck/Models/RealityCard.swift
import Foundation
import SwiftData

enum CardType: String, Codable, CaseIterable {
    case manual
    case formula
}

enum FormulaType: String, Codable, CaseIterable {
    case divide
    case count
    case subtract
    case countdown
}

@Model
final class RealityCard {
    var id: UUID
    var title: String
    var type: CardType
    var value: Double?
    var inputA: Double?
    var inputB: Double?
    var inputALabel: String?
    var inputBLabel: String?
    var formula: FormulaType?
    var targetDate: Date?
    var unit: String
    var contextLine: String
    var isPinned: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        title: String,
        type: CardType,
        formula: FormulaType? = nil,
        value: Double? = nil,
        inputA: Double? = nil,
        inputALabel: String? = nil,
        inputB: Double? = nil,
        inputBLabel: String? = nil,
        targetDate: Date? = nil,
        unit: String,
        contextLine: String,
        isPinned: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.type = type
        self.formula = formula
        self.value = value
        self.inputA = inputA
        self.inputALabel = inputALabel
        self.inputB = inputB
        self.inputBLabel = inputBLabel
        self.targetDate = targetDate
        self.unit = unit
        self.contextLine = contextLine
        self.isPinned = isPinned
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
