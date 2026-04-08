// RealityCheck/Views/CardDetailView.swift
import SwiftUI

struct CardDetailView: View {
    let selection: RealityCard?

    var body: some View {
        if let card = selection {
            CardFormView(card: card)
        } else {
            emptyPlaceholder
        }
    }

    private var emptyPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.on.rectangle")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("card.detail.placeholder")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
