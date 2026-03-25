// RealityCheck/Previews/GlassField+Preview.swift
import SwiftUI

#Preview {
    @Previewable @State var title = ""
    ZStack {
        AuroraBackground()
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel("Tiêu đề")
            GlassField("Nhập tiêu đề...", text: $title)
            SectionLabel("Giá trị")
            GlassField("0", text: .constant("15000000"))
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
