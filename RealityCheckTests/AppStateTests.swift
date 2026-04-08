// RealityCheckTests/AppStateTests.swift
import Testing
@testable import RealityCheck

@Suite("AppState")
struct AppStateTests {

    @Test("pendingAction starts as none")
    func initialState() {
        let state = AppState()
        #expect(state.pendingAction == .none)
    }

    @Test("pendingAction transitions to openCreateForm then back to none")
    func pendingActionCycle() {
        let state = AppState()
        state.pendingAction = .openCreateForm
        #expect(state.pendingAction == .openCreateForm)
        state.pendingAction = .none
        #expect(state.pendingAction == .none)
    }
}
