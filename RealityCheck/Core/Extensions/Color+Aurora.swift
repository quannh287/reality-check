// RealityCheck/Core/Extensions/Color+Aurora.swift
import SwiftUI

// MARK: - Hex initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    static let auroraGreen  = Color(hex: "#00f5a0")
    static let auroraTeal   = Color(hex: "#64dfdf")
    static let auroraPurple = Color(hex: "#c77dff")
    static let auroraRed    = Color(hex: "#ff6b6b")
    static let auroraYellow = Color(hex: "#ffd93d")
    static let auroraBlue   = Color(hex: "#00b4ff")
}

// MARK: - Accent color per type

extension FormulaType {
    var accentColor: Color {
        switch self {
        case .divide:    return .auroraTeal
        case .count:     return .auroraPurple
        case .subtract:  return .auroraYellow
        case .countdown: return .auroraGreen
        }
    }
}

extension CardType {
    var accentColor: Color { .auroraRed }
}
