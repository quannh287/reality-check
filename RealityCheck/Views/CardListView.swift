// RealityCheck/Views/CardListView.swift
import SwiftUI
import SwiftData
import WidgetKit

struct CardListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RealityCard.updatedAt, order: .reverse) private var cards: [RealityCard]
    @State private var showingCreateForm = false
    @State private var showingSettings = false
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingCreateForm = true } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .navigationDestination(isPresented: $showingSettings) {
                SettingsView()
            }
            .navigationDestination(for: RealityCard.self) { card in
                CardFormView(card: card)
                    .navigationTransition(.zoom(sourceID: card.id, in: namespace))
            }
            .sheet(isPresented: $showingCreateForm) {
                NavigationStack { CardFormView(card: nil) }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.4)) { appeared = true }
        }
    }

    // MARK: - Card content

    @ViewBuilder
    private var cardContent: some View {
        // Pinned section
        if let pinned = pinnedCard {
            SectionLabel("📍 Widget hiện tại")
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
                SectionLabel("Các card khác")
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
                    Button { pinCard(card) } label: {
                        Label("Pin lên widget", systemImage: "pin")
                    }
                    Button(role: .destructive) {
                        modelContext.delete(card)
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
                .foregroundStyle(.quaternary)
                .padding(.top, 60)

            Text("Chưa có Reality Card nào")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Tạo card đầu tiên để\nđối diện thực tế")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            GlassButton("＋ Tạo card đầu tiên", style: .primary) {
                showingCreateForm = true
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func pinCard(_ card: RealityCard) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            for c in cards where c.isPinned { c.isPinned = false }
            card.isPinned = true
            card.updatedAt = Date()
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview("Có cards") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RealityCard.self, configurations: config)
    let pinned = RealityCard(
        title: "Đến deadline",
        type: .formula,
        formula: .countdown,
        targetDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
        unit: "ngày",
        contextLine: "còn bao nhiêu ngày",
        isPinned: true
    )
    let other = RealityCard(
        title: "Chi phí tháng",
        type: .manual,
        value: 15_000_000,
        unit: "VNĐ",
        contextLine: "chi phí cố định mỗi tháng"
    )
    container.mainContext.insert(pinned)
    container.mainContext.insert(other)
    return ZStack {
        AuroraBackground()
        CardListView()
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}

#Preview("Trống") {
    ZStack {
        AuroraBackground()
        CardListView()
    }
    .modelContainer(for: RealityCard.self, inMemory: true)
    .preferredColorScheme(.dark)
}
