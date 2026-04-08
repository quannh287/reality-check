// RealityCheck/App/AppState.swift
import SwiftUI

@Observable
final class AppState {
    enum PendingAction {
        case none
        case openCreateForm
    }

    var pendingAction: PendingAction = .none
}
