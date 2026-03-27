// RealityCheck/Previews/PreviewSampleData.swift
import SwiftData
import Foundation

@MainActor
let previewContainer: ModelContainer = {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RealityCard.self, configurations: config)

    let pinned = RealityCard(
        title: "Chi phí tháng này",
        type: .manual,
        value: 4_200_000,
        unit: "đ",
        contextLine: "so với tháng trước",
        isPinned: true
    )

    let countdown = RealityCard(
        title: "Deadline project",
        type: .formula,
        formula: .countdown,
        targetDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
        unit: "ngày",
        contextLine: "còn lại"
    )

    let unpinned = RealityCard(
        title: "Tỉ lệ hoàn thành",
        type: .formula,
        formula: .divide,
        inputA: 7,
        inputALabel: "task xong",
        inputB: 10,
        inputBLabel: "tổng task",
        unit: "%",
        contextLine: "sprint hiện tại"
    )

    container.mainContext.insert(pinned)
    container.mainContext.insert(countdown)
    container.mainContext.insert(unpinned)
    return container
}()
