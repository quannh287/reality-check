// RealityCheck/GlassKit/AuroraBackground.swift
import SwiftUI

// MARK: - Color Extensions

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

// MARK: - Accent color per formula type

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

// MARK: - AuroraBackground

struct AuroraBackground: View {
    @State private var phase1 = false
    @State private var phase2 = false
    @State private var phase3 = false

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [Color(hex: "#060d1b"), Color(hex: "#0d1b2a"), Color(hex: "#071a0f")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Orb 1 — green, top-left, 8s
            GeometryReader { geo in
                Circle()
                    .fill(Color.auroraGreen.opacity(0.14))
                    .frame(width: geo.size.width * 0.6, height: geo.size.width * 0.6)
                    .blur(radius: 80)
                    .offset(
                        x: phase1 ? -geo.size.width * 0.05 : geo.size.width * 0.02,
                        y: phase1 ? -geo.size.height * 0.03 : geo.size.height * 0.04
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                // Orb 2 — blue, top-right, 10s
                Circle()
                    .fill(Color.auroraBlue.opacity(0.12))
                    .frame(width: geo.size.width * 0.5, height: geo.size.width * 0.5)
                    .blur(radius: 70)
                    .offset(
                        x: phase2 ? geo.size.width * 0.04 : -geo.size.width * 0.03,
                        y: phase2 ? -geo.size.height * 0.04 : geo.size.height * 0.02
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                // Orb 3 — purple, bottom-center, 12s
                Circle()
                    .fill(Color(hex: "#5a3cff").opacity(0.10))
                    .frame(width: geo.size.width * 0.55, height: geo.size.width * 0.55)
                    .blur(radius: 75)
                    .offset(
                        x: phase3 ? geo.size.width * 0.06 : -geo.size.width * 0.04,
                        y: phase3 ? geo.size.height * 0.03 : -geo.size.height * 0.02
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) { phase1.toggle() }
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true).delay(1)) { phase2.toggle() }
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true).delay(2)) { phase3.toggle() }
        }
    }
}
