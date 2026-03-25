// RealityCheck/Views/CardListView.swift
import SwiftUI
import SwiftData

struct CardListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RealityCard.updatedAt, order: .reverse) private var cards: [RealityCard]
    @State private var viewModel = CardListViewModel()
    @State private var showingCreateForm = false
    @State private var appeared = false
    @State private var cardToDelete: RealityCard? = nil
    @Namespace private var namespace

    private var pinnedCard: RealityCard? { cards.first(where: \.isPinned) }
    private var unpinnedCards: [RealityCard] { cards.filter { !$0.isPinned } }

    var body: some View {
        NavigationStack {
            List {
                if cards.isEmpty {
                    emptyState
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                } else {
                    cardContent
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .navigationTitle("Reality Check")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
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
            .alert("Xoá thẻ?", isPresented: Binding(
                get: { cardToDelete != nil },
                set: { if !$0 { cardToDelete = nil } }
            )) {
                Button("Xoá", role: .destructive) {
                    if let card = cardToDelete {
                        viewModel.deleteCard(card, context: modelContext)
                    }
                }
                Button("Huỷ", role: .cancel) { cardToDelete = nil }
            } message: {
                Text("Hành động này không thể hoàn tác.")
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
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))

            NavigationLink(value: pinned) {
                GlassCard(card: pinned, style: .pinned)
            }
            .buttonStyle(.plain)
            .matchedTransitionSource(id: pinned.id, in: namespace)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
            .animation(.spring(duration: 0.4).delay(0.06), value: appeared)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    cardToDelete = pinned
                } label: {
                    Label("Xoá", systemImage: "trash")
                }
                Button {
                    viewModel.unpinCard(pinned, context: modelContext)
                } label: {
                    Label("Bỏ ghim", systemImage: "pin.slash")
                }
                .tint(.auroraYellow)
            }
        }

        // Unpinned section
        if !unpinnedCards.isEmpty {
            if pinnedCard != nil {
                SectionLabel("Tất cả thẻ")
                    .padding(.top, 4)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(.spring(duration: 0.4).delay(0.03), value: appeared)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
            }

            ForEach(Array(unpinnedCards.enumerated()), id: \.element.id) { index, card in
                NavigationLink(value: card) {
                    GlassCard(card: card, style: .unpinned)
                }
                .buttonStyle(.plain)
                .matchedTransitionSource(id: card.id, in: namespace)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(
                    .spring(duration: 0.4).delay(Double(index + 1) * 0.06),
                    value: appeared
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        cardToDelete = card
                    } label: {
                        Label("Xoá", systemImage: "trash")
                    }
                    Button {
                        viewModel.pinCard(card, from: cards, context: modelContext)
                    } label: {
                        Label("Ghim", systemImage: "pin")
                    }
                    .tint(.auroraGreen)
                }
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

