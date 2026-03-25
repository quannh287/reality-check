// RealityCheck/GlassKit/FormulaChip.swift
import SwiftUI

struct FormulaChip: View {
    @Binding var selected: FormulaType

    private let options: [(type: FormulaType, icon: String, label: String)] = [
        (.divide,    "÷", "Chia A÷B"),
        (.count,     "/", "Đếm A/B"),
        (.subtract,  "−", "Trừ A−B"),
        (.countdown, "⏱", "Countdown"),
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
            ForEach(options, id: \.type) { option in
                chipButton(option)
            }
        }
    }

    private func chipButton(_ option: (type: FormulaType, icon: String, label: String)) -> some View {
        let isSelected = selected == option.type
        let accent = option.type.accentColor

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                selected = option.type
            }
        } label: {
            VStack(spacing: 3) {
                Text(option.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? accent : .secondary)
                Text(option.label)
                    .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? accent : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .modifier(GlassSurfaceModifier(
                accent: isSelected ? accent : .white,
                accentOpacity: isSelected ? 0.16 : 0.04,
                cornerRadius: 10,
                shadowRadius: isSelected ? 8 : 4
            ))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

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
