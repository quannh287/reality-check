// RealityCheck/App/AppDelegate.swift
#if targetEnvironment(macCatalyst)
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: UIApplication) -> Bool {
        return false
    }
}
#endif
