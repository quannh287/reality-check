// RealityCheck/Previews/MenuBarCardView+Preview.swift
import SwiftUI
import SwiftData

#Preview("MenuBar — with pinned card") {
    MenuBarCardView()
        .modelContainer(previewContainer)
        .environment(AppState())
}

#Preview("MenuBar — no pinned card") {
    MenuBarCardView()
        .modelContainer(try! ModelContainer(for: RealityCard.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
        .environment(AppState())
}
