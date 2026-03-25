// RealityCheck/GlassKit/GlassButton.swift
import SwiftUI

enum GlassButtonStyle {
    case primary   // Aurora green
    case secondary // White glass
    case destructive // Red
}

struct GlassButton: View {
    let label: String
    var style: GlassButtonStyle = .secondary
    var isDisabled: Bool = false
    let action: () -> Void

    init(_ label: String, style: GlassButtonStyle = .secondary, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.label = label
        self.style = style
        self.isDisabled = isDisabled
        self.action = action
    }

    private var accentColor: Color {
        switch style {
        case .primary:     return .auroraGreen
        case .secondary:   return .white
        case .destructive: return .auroraRed
        }
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: style == .primary ? .semibold : .medium))
                .foregroundStyle(
                    style == .primary
                        ? Color(hex: "#c8ffe0").opacity(isDisabled ? 0.4 : 0.9)
                        : Color.white.opacity(isDisabled ? 0.3 : 0.7)
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .modifier(GlassSurfaceModifier(
                    accent: accentColor,
                    accentOpacity: style == .primary ? 0.35 : 0.12,
                    cornerRadius: 10,
                    shadowRadius: style == .primary ? 10 : 6
                ))
                .shadow(
                    color: style == .primary ? Color.auroraGreen.opacity(isDisabled ? 0 : 0.25) : .clear,
                    radius: 8
                )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }
}
