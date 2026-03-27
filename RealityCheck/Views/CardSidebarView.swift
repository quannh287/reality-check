// RealityCheck/Views/CardSidebarView.swift
import SwiftUI
import SwiftData

struct CardSidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \RealityCard.updatedAt, order: .reverse) private var cards: [RealityCard]
    @Binding var selection: RealityCard?
    @State private var viewModel = CardListViewModel()
    @State private var showingCreateForm = false
    @State private var appeared = false
    @State private var cardToDelete: RealityCard? = nil
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
            .navigationTitle(String(localized: "app.title"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button { showingCreateForm = true } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingCreateForm) {
                NavigationStack { CardFormView(card: nil) }
            }
            .alert(String(localized: "card.list.alert.delete.title"), isPresented: Binding(
                get: { cardToDelete != nil },
                set: { if !$0 { cardToDelete = nil } }
            )) {
                Button(String(localized: "card.list.action.delete"), role: .destructive) {
                    if let card = cardToDelete {
                        viewModel.deleteCard(card, context: modelContext)
                    }
                }
                Button(String(localized: "card.form.action.cancel"), role: .cancel) { cardToDelete = nil }
            } message: {
                Text("card.list.alert.delete.message")
            }
        }
        .background(.clear)
        .onAppear {
            withAnimation(.spring(duration: 0.4)) { appeared = true }
        }
        .onChange(of: appState.pendingAction) { _, newValue in
            if newValue == .openCreateForm {
                showingCreateForm = true
                appState.pendingAction = .none
            }
        }
    }

    // MARK: - Card content

    @ViewBuilder
    private var cardContent: some View {
        if let pinned = pinnedCard {
            SectionLabel(String(localized: "card.list.section.pinned"))
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)
                .animation(.spring(duration: 0.4), value: appeared)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))

            Button {
                selection = pinned
            } label: {
                GlassCard(card: pinned, style: .pinned)
            }
            .buttonStyle(.plain)
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
                    Label(String(localized: "card.list.action.delete"), systemImage: "trash")
                }
                Button {
                    viewModel.unpinCard(pinned, context: modelContext)
                } label: {
                    Label(String(localized: "card.list.action.unpin"), systemImage: "pin.slash")
                }
                .tint(.auroraYellow)
            }
        }

        if !unpinnedCards.isEmpty {
            if pinnedCard != nil {
                SectionLabel(String(localized: "card.list.section.all"))
                    .padding(.top, 4)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(.spring(duration: 0.4).delay(0.03), value: appeared)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
            }

            ForEach(Array(unpinnedCards.enumerated()), id: \.element.id) { index, card in
                Button {
                    selection = card
                } label: {
                    GlassCard(card: card, style: .unpinned)
                }
                .buttonStyle(.plain)
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
                        Label(String(localized: "card.list.action.delete"), systemImage: "trash")
                    }
                    Button {
                        viewModel.pinCard(card, from: cards, context: modelContext)
                    } label: {
                        Label(String(localized: "card.list.action.pin.short"), systemImage: "pin")
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

            Text("card.list.empty.headline")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("card.list.empty.subheadline")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            GlassButton(String(localized: "card.list.empty.cta"), style: .primary) {
                showingCreateForm = true
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }
}
