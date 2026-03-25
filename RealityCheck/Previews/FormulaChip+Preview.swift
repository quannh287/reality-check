// RealityCheck/Previews/FormulaChip+Preview.swift
import SwiftUI

#Preview {
    @Previewable @State var selected: FormulaType = .divide
    ZStack {
        AuroraBackground()
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel("Chọn công thức")
            FormulaChip(selected: $selected)
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
