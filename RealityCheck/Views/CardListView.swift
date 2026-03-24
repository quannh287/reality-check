import SwiftUI
import SwiftData
import WidgetKit

struct CardListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RealityCard.updatedAt, order: .reverse) private var cards: [RealityCard]
    @State private var showingCreateForm = false

    private var pinnedCard: RealityCard? {
        cards.first(where: \.isPinned)
    }

    private var unpinnedCards: [RealityCard] {
        cards.filter { !$0.isPinned }
    }

    var body: some View {
        NavigationStack {
            List {
                if let pinned = pinnedCard {
                    Section {
                        CardRowView(card: pinned)
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(red: 1, green: 0.267, blue: 0.267), lineWidth: 1)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(.clear))
                            )
                    } header: {
                        Label("Đang hiện trên Widget", systemImage: "pin.fill")
                    }
                }

                Section {
                    if unpinnedCards.isEmpty && pinnedCard == nil {
                        ContentUnavailableView(
                            "Chưa có Reality Card nào",
                            systemImage: "rectangle.stack.badge.plus",
                            description: Text("Tạo card đầu tiên để đối diện thực tế")
                        )
                    }
                    ForEach(unpinnedCards) { card in
                        NavigationLink(value: card) {
                            CardRowView(card: card)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                modelContext.delete(card)
                            } label: {
                                Label("Xoá", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                pinCard(card)
                            } label: {
                                Label("Pin", systemImage: "pin")
                            }
                            .tint(.orange)
                        }
                    }
                } header: {
                    if pinnedCard != nil {
                        Text("Các card khác")
                    }
                }
            }
            .navigationTitle("Reality Check")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
            .navigationDestination(for: RealityCard.self) { card in
                CardFormView(card: card)
            }
            .sheet(isPresented: $showingCreateForm) {
                NavigationStack {
                    CardFormView(card: nil)
                }
            }
        }
    }

    private func pinCard(_ card: RealityCard) {
        for c in cards where c.isPinned {
            c.isPinned = false
        }
        card.isPinned = true
        card.updatedAt = Date()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
