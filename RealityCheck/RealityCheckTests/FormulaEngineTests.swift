// RealityCheckTests/FormulaEngineTests.swift
import Testing
import Foundation
@testable import RealityCheck

@Suite("FormulaEngine")
struct FormulaEngineTests {

    @Test("Manual card returns value as display string")
    func manualValue() {
        let card = RealityCard(
            title: "Chi phí", type: .manual,
            value: 15_000_000, unit: "triệu",
            contextLine: "chi phí cố định"
        )
        #expect(FormulaEngine.displayValue(for: card) == "15000000")
    }

    @Test("Manual card with nil value returns --")
    func manualNilValue() {
        let card = RealityCard(
            title: "Test", type: .manual,
            value: nil, unit: "x", contextLine: "test"
        )
        #expect(FormulaEngine.displayValue(for: card) == "--")
    }

    @Test("Divide formula computes A / B")
    func divideFormula() {
        let card = RealityCard(
            title: "Runway", type: .formula, formula: .divide,
            inputA: 30_000_000, inputB: 15_000_000,
            unit: "tháng", contextLine: "runway"
        )
        #expect(FormulaEngine.displayValue(for: card) == "2")
    }

    @Test("Divide by zero returns infinity symbol")
    func divideByZero() {
        let card = RealityCard(
            title: "Test", type: .formula, formula: .divide,
            inputA: 100, inputB: 0,
            unit: "x", contextLine: "test"
        )
        #expect(FormulaEngine.displayValue(for: card) == "∞")
    }

    @Test("Count formula returns A/B format")
    func countFormula() {
        let card = RealityCard(
            title: "Jobs", type: .formula, formula: .count,
            inputA: 1, inputB: 3,
            unit: "job", contextLine: "confirmed"
        )
        #expect(FormulaEngine.displayValue(for: card) == "1/3")
    }

    @Test("Subtract formula computes A - B")
    func subtractFormula() {
        let card = RealityCard(
            title: "Dư", type: .formula, formula: .subtract,
            inputA: 20_000_000, inputB: 15_000_000,
            unit: "triệu", contextLine: "dư hàng tháng"
        )
        #expect(FormulaEngine.displayValue(for: card) == "5000000")
    }

    @Test("Countdown formula returns days until target")
    func countdownFormula() {
        let target = Calendar.current.date(byAdding: .day, value: 12, to: Date())!
        let card = RealityCard(
            title: "Deadline", type: .formula, formula: .countdown,
            targetDate: target,
            unit: "ngày", contextLine: "đến deadline"
        )
        let result = FormulaEngine.displayValue(for: card)
        #expect(result == "12" || result == "11")
    }

    @Test("Countdown past date returns 0")
    func countdownPastDate() {
        let target = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let card = RealityCard(
            title: "Past", type: .formula, formula: .countdown,
            targetDate: target,
            unit: "ngày", contextLine: "đã qua"
        )
        #expect(FormulaEngine.displayValue(for: card) == "0")
    }

    @Test("Formula card with missing inputs returns --")
    func formulaMissingInputs() {
        let card = RealityCard(
            title: "Bad", type: .formula, formula: .divide,
            inputA: nil, inputB: nil,
            unit: "x", contextLine: "test"
        )
        #expect(FormulaEngine.displayValue(for: card) == "--")
    }
}
