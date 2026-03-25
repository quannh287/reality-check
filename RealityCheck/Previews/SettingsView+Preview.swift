// RealityCheck/Previews/SettingsView+Preview.swift
import SwiftUI
import SwiftData

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: RealityCard.self, inMemory: true)
    .background(AuroraBackground())
    .preferredColorScheme(.dark)
}
