// RealityCheck/App/RealityCheckApp.swift
import SwiftUI
import SwiftData
#if DEBUG
import DebugSwift
#endif

@main
struct RealityCheckApp: App {
    #if targetEnvironment(macCatalyst)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    @State private var selectedCard: RealityCard?
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var appState = AppState()

    private let sharedContainer: ModelContainer = {
        try! ModelContainer(
            for: RealityCard.self,
            configurations: AppGroupContainer.modelConfiguration
        )
    }()

    init() {
        NotificationService.requestPermission()
        #if DEBUG
        setupDebugSwift()
        #endif
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ZStack {
                AuroraBackground()
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    CardSidebarView(selection: $selectedCard)
                } detail: {
                    CardDetailView(selection: selectedCard)
                }
            }
            .preferredColorScheme(.dark)
            .environment(appState)
        }
        .modelContainer(sharedContainer)

        #if targetEnvironment(macCatalyst)
        MenuBarExtra("Reality Check", systemImage: "pin.circle.fill") {
            MenuBarCardView()
                .modelContainer(sharedContainer)
                .environment(appState)
        }
        .menuBarExtraStyle(.window)
        #endif
    }

    #if DEBUG
    @MainActor
    private func setupDebugSwift() {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
        DebugSwift().setup().show()
    }
    #endif
}
