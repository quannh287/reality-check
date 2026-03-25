// RealityCheck/GlassKit/GlassField.swift
import SwiftUI

struct GlassField: View {
    let placeholder: String
    @Binding var text: String
    var font: Font = .body
    #if canImport(UIKit)
    var keyboardType: UIKeyboardType = .default

    init(_ placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default, font: Font = .body) {
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.font = font
    }
    #else
    init(_ placeholder: String, text: Binding<String>, font: Font = .body) {
        self.placeholder = placeholder
        self._text = text
        self.font = font
    }
    #endif

    var body: some View {
        TextField(placeholder, text: $text)
            #if canImport(UIKit)
            .keyboardType(keyboardType)
            #endif
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
            .font(.system(size: 16, weight: .bold))
            .textCase(.uppercase)
            .tracking(1.4)
            .foregroundStyle(.primary)
            .padding(.leading, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

