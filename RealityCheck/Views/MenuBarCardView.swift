// RealityCheck/Views/MenuBarCardView.swift
import SwiftUI
import SwiftData

struct MenuBarCardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    @Query(filter: #Predicate<RealityCard> { $0.isPinned }) private var pinnedCards: [RealityCard]

    private var pinnedCard: RealityCard? { pinnedCards.first }

    var body: some View {
        ZStack {
            AuroraBackground()
            VStack(spacing: 0) {
                cardSection
                Divider()
                    .opacity(0.2)
                actionSection
            }
        }
        .frame(width: 320)
        .preferredColorScheme(.dark)
    }

    // MARK: - Card section

    private var cardSection: some View {
        Group {
            if let card = pinnedCard {
                GlassCard(card: card, style: .pinned)
                    .padding(16)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "pin.slash")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                    Text("menubar.empty")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Action section

    private var actionSection: some View {
        HStack {
            Button {
                openWindow(id: "main")
            } label: {
                Label("menubar.action.open", systemImage: "macwindow")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 20)
                .opacity(0.2)

            Button {
                openWindow(id: "main")
                appState.pendingAction = .openCreateForm
            } label: {
                Label("menubar.action.add", systemImage: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 20)
                .opacity(0.2)

            Button {
                exit(0)
            } label: {
                Label("menubar.action.quit", systemImage: "power")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
    }
}
