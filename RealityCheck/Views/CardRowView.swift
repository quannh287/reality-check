import SwiftUI

struct CardRowView: View {
    let card: RealityCard

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(FormulaEngine.displayValue(for: card))
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(Color(red: 1, green: 0.267, blue: 0.267))
                    Text(card.unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(card.contextLine)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Text(card.type.rawValue)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.vertical, 4)
    }
}
