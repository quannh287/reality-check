// RealityCheck/Views/CardListView.swift
import SwiftUI
import SwiftData

struct CardListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RealityCard.updatedAt, order: .reverse) private var cards: [RealityCard]
    @State private var viewModel = CardListViewModel()
    @State private var showingCreateForm = false
    @State private var appeared = false
    @Namespace private var namespace

    private var pinnedCard: RealityCard? { cards.first(where: \.isPinned) }
    private var unpinnedCards: [RealityCard] { cards.filter { !$0.isPinned } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    if cards.isEmpty {
                        emptyState
                    } else {
                        cardContent
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .navigationTitle("Reality Check")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingCreateForm = true } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationDestination(for: RealityCard.self) { card in
                CardFormView(card: card)
                    .navigationTransition(.zoom(sourceID: card.id, in: namespace))
            }
            .sheet(isPresented: $showingCreateForm) {
                NavigationStack { CardFormView(card: nil) }
            }
        }
        .background(.clear)
        .onAppear {
            withAnimation(.spring(duration: 0.4)) { appeared = true }
        }
    }

    // MARK: - Card content

    @ViewBuilder
    private var cardContent: some View {
        // Pinned section
        if let pinned = pinnedCard {
            SectionLabel("Đã ghim")
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)
                .animation(.spring(duration: 0.4), value: appeared)

            NavigationLink(value: pinned) {
                GlassCard(card: pinned, style: .pinned)
            }
            .buttonStyle(.plain)
            .matchedTransitionSource(id: pinned.id, in: namespace)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
            .animation(.spring(duration: 0.4).delay(0.06), value: appeared)
        }

        // Unpinned section
        if !unpinnedCards.isEmpty {
            if pinnedCard != nil {
                SectionLabel("Tất cả thẻ")
                    .padding(.top, 4)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.4).delay(0.03), value: appeared)
            }

            ForEach(Array(unpinnedCards.enumerated()), id: \.element.id) { index, card in
                NavigationLink(value: card) {
                    GlassCard(card: card, style: .unpinned)
                }
                .buttonStyle(.plain)
                .matchedTransitionSource(id: card.id, in: namespace)
                .contextMenu {
                    Button { viewModel.pinCard(card, from: cards, context: modelContext) } label: {
                        Label("Pin lên widget", systemImage: "pin")
                    }
                    Button(role: .destructive) {
                        viewModel.deleteCard(card, context: modelContext)
                    } label: {
                        Label("Xoá", systemImage: "trash")
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(
                    .spring(duration: 0.4).delay(Double(index + 1) * 0.06),
                    value: appeared
                )
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.primary)
                .padding(.top, 60)

            Text("Chưa có Reality Card nào")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Tạo card đầu tiên để\nđối diện thực tế")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            GlassButton("＋ Tạo card đầu tiên", style: .primary) {
                showingCreateForm = true
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

}

