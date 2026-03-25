// RealityCheck/GlassKit/GlassField.swift
import SwiftUI

struct GlassField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var font: Font = .body

    init(_ placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) {
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .font(font)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .glassField()
    }
}

// MARK: - Section label (inline sub-view)
struct SectionLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .textCase(.uppercase)
            .tracking(1.4)
            .foregroundStyle(.tertiary)
            .padding(.leading, 4)
    }
}
