import SwiftUI
import SwiftData

@main
struct RealityCheckApp: App {
    var body: some Scene {
        WindowGroup {
            CardListView()
        }
        .modelContainer(for: RealityCard.self)
    }
}
