import SwiftUI

struct WidgetPreviewView: View {
    let displayValue: String
    let unit: String
    let contextLine: String

    var body: some View {
        VStack(spacing: 2) {
            Text(displayValue)
                .font(.system(size: 36, weight: .heavy))
                .foregroundStyle(Color(red: 1, green: 0.267, blue: 0.267))
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
        .frame(width: 155, height: 155)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.quaternary)
                )
        )
    }
}
