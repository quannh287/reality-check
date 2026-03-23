import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("notificationEnabled") private var notificationEnabled = true
    @AppStorage("notificationHour") private var notificationHour = 8
    @AppStorage("notificationMinute") private var notificationMinute = 0

    @Query(filter: #Predicate<RealityCard> { $0.isPinned == true })
    private var pinnedCards: [RealityCard]

    private var notificationTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(
                    hour: notificationHour,
                    minute: notificationMinute
                )) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                notificationHour = components.hour ?? 8
                notificationMinute = components.minute ?? 0
                updateNotification()
            }
        )
    }

    var body: some View {
        Form {
            Section("Thông báo hàng ngày") {
                Toggle("Bật thông báo", isOn: $notificationEnabled)
                    .onChange(of: notificationEnabled) { _, enabled in
                        if enabled {
                            NotificationService.requestPermission()
                            updateNotification()
                        } else {
                            NotificationService.cancelDailyNotification()
                        }
                    }

                if notificationEnabled {
                    DatePicker(
                        "Thời gian nhắc",
                        selection: notificationTime,
                        displayedComponents: .hourAndMinute
                    )
                }
            }
        }
        .navigationTitle("Cài đặt")
        .onAppear {
            if notificationEnabled {
                NotificationService.requestPermission()
            }
        }
    }

    private func updateNotification() {
        guard notificationEnabled else { return }
        NotificationService.scheduleDailyNotification(
            for: pinnedCards.first,
            hour: notificationHour,
            minute: notificationMinute
        )
    }
}
