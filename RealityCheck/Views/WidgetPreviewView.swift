// RealityCheck/Views/WidgetPreviewView.swift
import SwiftUI

struct WidgetPreviewView: View {
    let displayValue: String
    let unit: String
    let contextLine: String
    var accentColor: Color = .auroraRed

    var body: some View {
        ZStack {
            // Glass background
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.25),
                            accentColor.opacity(0.08),
                            accentColor.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.5),
                                    accentColor.opacity(0.2),
                                    accentColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            // Orb overlay (static in preview)
            Circle()
                .fill(accentColor.opacity(0.22))
                .frame(width: 80, height: 80)
                .blur(radius: 30)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: 10, y: -10)

            // Content
            VStack(spacing: 2) {
                Text(displayValue)
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(accentColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(unit.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                Text(contextLine)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
            }
            .padding(12)

            // Shimmer
            ShimmerView()
                .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .frame(width: 155, height: 155)
        .shadow(color: accentColor.opacity(0.2), radius: 16, y: 8)
    }
}

#Preview {
    ZStack {
        AuroraBackground()
        VStack(spacing: 24) {
            WidgetPreviewView(
                displayValue: "47",
                unit: "ngày",
                contextLine: "runway nếu nghỉ việc hôm nay",
                accentColor: .auroraGreen
            )
            WidgetPreviewView(
                displayValue: "20",
                unit: "tháng",
                contextLine: "còn sống được nếu nghỉ việc",
                accentColor: .auroraTeal
            )
        }
    }
    .preferredColorScheme(.dark)
}
