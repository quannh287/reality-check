// RealityCheck/Previews/GlassToggle+Preview.swift
import SwiftUI

#Preview {
    @Previewable @State var isOn = false
    ZStack {
        AuroraBackground()
        HStack(spacing: 24) {
            GlassToggle(isOn: .constant(false))
            GlassToggle(isOn: .constant(true))
            GlassToggle(isOn: $isOn)
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
