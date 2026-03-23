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
        }
        .modelContainer(for: RealityCard.self)
    }
}
