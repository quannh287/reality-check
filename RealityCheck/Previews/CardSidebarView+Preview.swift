// RealityCheck/Previews/CardSidebarView+Preview.swift
import SwiftUI
import SwiftData

#Preview("Sidebar — with cards") {
    ZStack {
        AuroraBackground()
        CardSidebarView(selection: .constant(nil))
    }
    .preferredColorScheme(.dark)
    .modelContainer(previewContainer)
    .environment(AppState())
}

#Preview("Sidebar — swipe actions") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RealityCard.self, configurations: config)
    let pinned = RealityCard(
        title: "Runway",
        type: .formula,
        formula: .divide,
        inputA: 300_000_000,
        inputALabel: "Tiết kiệm",
        inputB: 15_000_000,
        inputBLabel: "Chi phí / tháng",
        unit: "tháng",
        contextLine: "← kéo trái để bỏ ghim / xoá",
        isPinned: true
    )
    let unpinned = RealityCard(
        title: "Chi phí tháng",
        type: .manual,
        value: 15_000_000,
        unit: "VNĐ",
        contextLine: "← kéo trái để ghim / xoá"
    )
    container.mainContext.insert(pinned)
    container.mainContext.insert(unpinned)
    return ZStack {
        AuroraBackground()
        CardSidebarView(selection: .constant(nil))
    }
    .preferredColorScheme(.dark)
    .modelContainer(container)
    .environment(AppState())
}

#Preview("Sidebar — empty") {
    ZStack {
        AuroraBackground()
        CardSidebarView(selection: .constant(nil))
    }
    .preferredColorScheme(.dark)
    .modelContainer(try! ModelContainer(for: RealityCard.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    .environment(AppState())
}
