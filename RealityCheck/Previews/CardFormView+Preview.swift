// RealityCheck/Previews/CardFormView+Preview.swift
import SwiftUI
import SwiftData

#Preview("Tạo mới") {
    NavigationStack {
        CardFormView(card: nil)
    }
    .modelContainer(for: RealityCard.self, inMemory: true)
    .background(AuroraBackground())
    .preferredColorScheme(.dark)
}

#Preview("Chỉnh sửa") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RealityCard.self, configurations: config)
    let card = RealityCard(
        title: "Runway",
        type: .formula,
        formula: .divide,
        inputA: 300_000_000,
        inputALabel: "Tiết kiệm",
        inputB: 15_000_000,
        inputBLabel: "Chi phí / tháng",
        unit: "tháng",
        contextLine: "còn sống được nếu nghỉ việc"
    )
    container.mainContext.insert(card)
    return NavigationStack {
        CardFormView(card: card)
    }
    .modelContainer(container)
    .background(AuroraBackground())
    .preferredColorScheme(.dark)
}
