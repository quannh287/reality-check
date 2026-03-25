// RealityCheck/Previews/GlassButton+Preview.swift
import SwiftUI

#Preview {
    ZStack {
        AuroraBackground()
        VStack(spacing: 12) {
            GlassButton("Lưu card", style: .primary) {}
            GlassButton("Huỷ", style: .secondary) {}
            GlassButton("Xoá card", style: .destructive) {}
            GlassButton("Đang tải...", style: .primary, isDisabled: true) {}
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
