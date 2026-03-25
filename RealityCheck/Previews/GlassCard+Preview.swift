// RealityCheck/Previews/GlassCard+Preview.swift
import SwiftUI

#Preview {
    let pinned = RealityCard(
        title: "Chi phí tháng",
        type: .manual,
        value: 15_000_000,
        unit: "VNĐ",
        contextLine: "chi phí cố định mỗi tháng",
        isPinned: true
    )
    let formula = RealityCard(
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
    ZStack {
        AuroraBackground()
        VStack(spacing: 12) {
            GlassCard(card: pinned, style: .pinned)
            GlassCard(card: formula, style: .unpinned)
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
