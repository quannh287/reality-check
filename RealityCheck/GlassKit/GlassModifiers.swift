// RealityCheck/GlassKit/GlassModifiers.swift
import SwiftUI

// MARK: - Corner radius helpers

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - Glass surface ViewModifier

struct GlassSurfaceModifier: ViewModifier {
    var accent: Color
    var accentOpacity: Double
    var cornerRadius: CGFloat
    var shadowRadius: CGFloat

    init(
        accent: Color = .white,
        accentOpacity: Double = 0.17,
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 14
    ) {
        self.accent = accent
        self.accentOpacity = accentOpacity
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }

    func body(content: Content) -> some View {
        content
            .background(glassBackground)
            .overlay(specularBorder)
            .shadow(color: .black.opacity(0.35), radius: shadowRadius, y: 8)
    }

    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial)
            .overlay(
                LinearGradient(
                    colors: [
                        accent.opacity(accentOpacity * 1.5),
                        accent.opacity(accentOpacity * 0.4),
                        accent.opacity(accentOpacity)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var specularBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.42),
                        Color.white.opacity(0.18),
                        Color.white.opacity(0.12),
                        Color.white.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

// MARK: - View extensions

extension View {
    /// Standard glass card surface (cornerRadius 16)
    func glassCard(accent: Color = .white, accentOpacity: Double = 0.17) -> some View {
        modifier(GlassSurfaceModifier(accent: accent, accentOpacity: accentOpacity, cornerRadius: 16))
    }

    /// Compact glass surface for fields/buttons (cornerRadius 10)
    func glassField() -> some View {
        modifier(GlassSurfaceModifier(
            accent: .white, accentOpacity: 0.065,
            cornerRadius: 10, shadowRadius: 6
        ))
    }

    /// Glass row surface with custom corner radii (for grouped rows)
    func glassRow(topRadius: CGFloat = 14, bottomRadius: CGFloat = 14) -> some View {
        // Build a single Path combining top and bottom rounded corners so we can stroke it
        self
            .background(.ultraThinMaterial.opacity(0.8))
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(0.065), Color.white.opacity(0.04)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .overlay(
                GeometryReader { geo in
                    let r = geo.size
                    Path { p in
                        // Combined shape: top rounded corners + bottom rounded corners
                        p.addPath(RoundedCorner(radius: topRadius, corners: [.topLeft, .topRight]).path(in: CGRect(origin: .zero, size: r)))
                        p.addPath(RoundedCorner(radius: bottomRadius, corners: [.bottomLeft, .bottomRight]).path(in: CGRect(origin: .zero, size: r)))
                    }
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.22), Color.white.opacity(0.08)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                }
            )
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: topRadius,
                    bottomLeadingRadius: bottomRadius,
                    bottomTrailingRadius: bottomRadius,
                    topTrailingRadius: topRadius
                )
            )
    }
}

// MARK: - Shimmer overlay

struct ShimmerView: View {
    @State private var isShimmering = false

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.07), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(width: geo.size.width * 0.4)
                .offset(x: isShimmering ? geo.size.width * 1.4 : -geo.size.width * 0.6)
        }
        .clipped()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(
                .linear(duration: 1.2)
                .repeatForever(autoreverses: false)
                .delay(3)
            ) {
                isShimmering = true
            }
        }
    }
}
