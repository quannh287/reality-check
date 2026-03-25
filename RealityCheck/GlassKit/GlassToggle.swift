// RealityCheck/GlassKit/GlassToggle.swift
import SwiftUI

struct GlassToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        ZStack {
            // Track
            Capsule()
                .fill(isOn ? Color.auroraGreen.opacity(0.45) : Color.white.opacity(0.08))
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isOn ? Color.auroraGreen.opacity(0.5) : Color.white.opacity(0.14),
                            lineWidth: 1
                        )
                )
                .overlay(
                    // Specular highlight top
                    LinearGradient(
                        colors: [
                            (isOn ? Color.auroraGreen : .white).opacity(0.3),
                            .clear
                        ],
                        startPoint: .top, endPoint: .center
                    )
                    .clipShape(Capsule())
                )
                .frame(width: 44, height: 26)
                .shadow(color: isOn ? Color.auroraGreen.opacity(0.3) : .clear, radius: 6)

            // Thumb
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
                .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                .offset(x: isOn ? 9 : -9)
        }
        .frame(width: 44, height: 26)
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                isOn.toggle()
            }
        }
    }
}
