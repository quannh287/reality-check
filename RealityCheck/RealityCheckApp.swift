// RealityCheck/RealityCheckApp.swift
import SwiftUI
import SwiftData

@main
struct RealityCheckApp: App {
    init() {
        NotificationService.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            CardListView()
                .background(AuroraBackground())
                .preferredColorScheme(.dark)
        }
        .modelContainer(
            try! ModelContainer(
                for: RealityCard.self,
                configurations: AppGroupContainer.modelConfiguration
            )
        )
    }
}
