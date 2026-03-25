// RealityCheck/ViewModels/SettingsViewModel.swift
import Foundation

@Observable
final class SettingsViewModel {
    func updateNotification(pinnedCard: RealityCard?, hour: Int, minute: Int) {
        NotificationService.scheduleDailyNotification(
            for: pinnedCard,
            hour: hour,
            minute: minute
        )
    }
}
