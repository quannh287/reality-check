// RealityCheck/Previews/WidgetPreviewView+Preview.swift
import SwiftUI

#Preview {
    ZStack {
        AuroraBackground()
        VStack(spacing: 24) {
            WidgetPreviewView(
                displayValue: "47",
                unit: "ngày",
                contextLine: "runway nếu nghỉ việc hôm nay",
                accentColor: .auroraGreen
            )
            WidgetPreviewView(
                displayValue: "20",
                unit: "tháng",
                contextLine: "còn sống được nếu nghỉ việc",
                accentColor: .auroraTeal
            )
        }
    }
    .preferredColorScheme(.dark)
}
