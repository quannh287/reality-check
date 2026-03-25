import Foundation
import SwiftData

enum AppGroupContainer {
    static let groupID = "group.com.quannh.realitycheck"

    static var url: URL {
        // Fallback to default container if App Groups not configured yet
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: groupID
        ) else {
            return URL.applicationSupportDirectory.appending(path: "RealityCheck")
        }
        return url
    }

    static var modelConfiguration: ModelConfiguration {
        ModelConfiguration(
            "RealityCheck",
            url: url.appending(path: "RealityCheck.store")
        )
    }
}
