// RealityCheck/Previews/CardListView+Preview.swift
import SwiftUI
import SwiftData

#Preview("Có cards") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RealityCard.self, configurations: config)
    let pinned = RealityCard(
        title: "Đến deadline",
        type: .formula,
        formula: .countdown,
        targetDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
        unit: "ngày",
        contextLine: "còn bao nhiêu ngày",
        isPinned: true
    )
    let runway = RealityCard(
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
    let chiPhi = RealityCard(
        title: "Chi phí tháng",
        type: .manual,
        value: 15_000_000,
        unit: "VNĐ",
        contextLine: "chi phí cố định mỗi tháng"
    )
    let doanhSo = RealityCard(
        title: "Doanh số tháng",
        type: .formula,
        formula: .count,
        inputA: 7,
        inputALabel: "Đã chốt",
        inputB: 20,
        inputBLabel: "Mục tiêu",
        unit: "deal",
        contextLine: "tiến độ chốt deal tháng này"
    )
    let luong = RealityCard(
        title: "Tiết kiệm ròng",
        type: .formula,
        formula: .subtract,
        inputA: 32_000_000,
        inputALabel: "Thu nhập",
        inputB: 15_000_000,
        inputBLabel: "Chi phí",
        unit: "VNĐ",
        contextLine: "mỗi tháng để dành được"
    )
    container.mainContext.insert(pinned)
    container.mainContext.insert(runway)
    container.mainContext.insert(chiPhi)
    container.mainContext.insert(doanhSo)
    container.mainContext.insert(luong)
    return ZStack {
        AuroraBackground()
        CardListView()
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}

#Preview("Swipe actions") {
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
        CardListView()
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}

#Preview("Trống") {
    ZStack {
        AuroraBackground()
        CardListView()
    }
    .modelContainer(for: RealityCard.self, inMemory: true)
    .preferredColorScheme(.dark)
}
