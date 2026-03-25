// RealityCheck/RealityCheckApp.swift
import SwiftUI
import SwiftData
#if DEBUG
import DebugSwift
#endif

@main
struct RealityCheckApp: App {
    init() {
        NotificationService.requestPermission()
        #if DEBUG
        setupDebugSwift()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                AuroraBackground()
                CardListView()
            }
            .preferredColorScheme(.dark)
        }
        .modelContainer(
            try! ModelContainer(
                for: RealityCard.self,
                configurations: AppGroupContainer.modelConfiguration
            )
        )
    }

    #if DEBUG
    @MainActor
    private func setupDebugSwift() {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
        DebugSwift().setup().show()
    }
    #endif
}
