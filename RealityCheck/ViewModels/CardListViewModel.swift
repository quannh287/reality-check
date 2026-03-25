// RealityCheck/ViewModels/CardListViewModel.swift
import SwiftUI
import SwiftData
import WidgetKit

@Observable
final class CardListViewModel {
    func pinCard(_ card: RealityCard, from cards: [RealityCard], context: ModelContext) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            for c in cards where c.isPinned { c.isPinned = false }
            card.isPinned = true
            card.updatedAt = Date()
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    func deleteCard(_ card: RealityCard, context: ModelContext) {
        context.delete(card)
    }
}
