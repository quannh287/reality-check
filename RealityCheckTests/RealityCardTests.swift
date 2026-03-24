// RealityCheckTests/RealityCardTests.swift
import Testing
import Foundation
@testable import RealityCheck

@Suite("RealityCard Model")
struct RealityCardTests {

    @Test("Manual card stores value directly")
    func manualCard() {
        let card = RealityCard(
            title: "Chi phí",
            type: .manual,
            value: 15_000_000,
            unit: "triệu",
            contextLine: "chi phí cố định mỗi tháng"
        )
        #expect(card.title == "Chi phí")
        #expect(card.type == .manual)
        #expect(card.value == 15_000_000)
        #expect(card.isPinned == false)
    }

    @Test("Formula card stores inputs and formula type")
    func formulaCard() {
        let card = RealityCard(
            title: "Runway",
            type: .formula,
            formula: .divide,
            inputA: 30_000_000,
            inputALabel: "Tiết kiệm",
            inputB: 15_000_000,
            inputBLabel: "Chi phí / tháng",
            unit: "tháng",
            contextLine: "còn sống được nếu nghỉ việc"
        )
        #expect(card.type == .formula)
        #expect(card.formula == .divide)
        #expect(card.inputA == 30_000_000)
        #expect(card.inputB == 15_000_000)
    }

    @Test("Card has UUID and timestamps on creation")
    func cardMetadata() {
        let before = Date()
        let card = RealityCard(
            title: "Test",
            type: .manual,
            value: 1,
            unit: "x",
            contextLine: "test"
        )
        let after = Date()
        #expect(card.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        #expect(card.createdAt >= before)
        #expect(card.createdAt <= after)
        #expect(card.updatedAt >= before)
    }
}
