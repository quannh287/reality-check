// RealityCheck/Previews/CardDetailView+Preview.swift
import SwiftUI
import SwiftData

#Preview("Detail — with card") {
    ZStack {
        AuroraBackground()
        CardDetailView(selection: RealityCard(
            title: "Chi phí", type: .manual,
            value: 4_200_000, unit: "đ",
            contextLine: "tháng này"
        ))
    }
    .preferredColorScheme(.dark)
    .modelContainer(previewContainer)
}

#Preview("Detail — empty placeholder") {
    ZStack {
        AuroraBackground()
        CardDetailView(selection: nil)
    }
    .preferredColorScheme(.dark)
    .modelContainer(previewContainer)
}
