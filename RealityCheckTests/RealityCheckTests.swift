//
//  RealityCheckTests.swift
//  RealityCheckTests
//
//  Created by Nguyễn Hồng Quân on 23/3/26.
//

import Testing

struct RealityCheckTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}

// MARK: - CardListViewModelTests

import Foundation
import SwiftData
@testable import RealityCheck

@Suite("CardListViewModel")
struct CardListViewModelTests {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: RealityCard.self, configurations: config)
        return ModelContext(container)
    }

    @Test("unpinCard sets isPinned to false")
    func unpinCardSetsIsPinnedFalse() throws {
        let context = try makeContext()
        let card = RealityCard(title: "Test", type: .manual, unit: "", contextLine: "")
        card.isPinned = true
        context.insert(card)

        CardListViewModel().unpinCard(card, context: context)

        #expect(card.isPinned == false)
    }

    @Test("unpinCard updates updatedAt timestamp")
    func unpinCardUpdatesTimestamp() throws {
        let context = try makeContext()
        let card = RealityCard(title: "Test", type: .manual, unit: "", contextLine: "")
        card.isPinned = true
        context.insert(card)

        let before = Date()
        CardListViewModel().unpinCard(card, context: context)

        #expect(card.updatedAt >= before)
    }
}
