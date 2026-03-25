// RealityCheck/Views/SettingsView.swift
import SwiftUI
import SwiftData
import WidgetKit

struct SettingsView: View {
    @AppStorage("notificationEnabled") private var notificationEnabled = true
    @AppStorage("notificationHour")    private var notificationHour = 8
    @AppStorage("notificationMinute")  private var notificationMinute = 0

    @Query(filter: #Predicate<RealityCard> { $0.isPinned == true })
    private var pinnedCards: [RealityCard]

    private var notificationTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(
                    hour: notificationHour, minute: notificationMinute
                )) ?? Date()
            },
            set: { newDate in
                let c = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                notificationHour = c.hour ?? 8
                notificationMinute = c.minute ?? 0
                updateNotification()
            }
        )
    }

    private var timeString: String {
        String(format: "%02d:%02d", notificationHour, notificationMinute)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                // Thông báo section
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel("Thông báo hàng ngày")

                    VStack(spacing: 1) {
                        // Toggle row
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Bật thông báo")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Nhắc nhở Reality Card mỗi ngày")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            GlassToggle(isOn: $notificationEnabled)
                                .onChange(of: notificationEnabled) { _, enabled in
                                    if enabled {
                                        NotificationService.requestPermission()
                                        updateNotification()
                                    } else {
                                        NotificationService.cancelDailyNotification()
                                    }
                                }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .glassRow(topRadius: 14, bottomRadius: 5)

                        // Time row
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Thời gian nhắc")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Mỗi ngày vào lúc")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            // Large digit time picker
                            DatePicker("", selection: notificationTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .overlay(
                                    // Glass overlay showing HH:MM
                                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                                        Text(String(format: "%02d", notificationHour))
                                            .font(.system(size: 22, weight: .bold))
                                        Text(":")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(.tertiary)
                                        Text(String(format: "%02d", notificationMinute))
                                            .font(.system(size: 22, weight: .bold))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .glassCard()
                                    .allowsHitTesting(false)
                                )
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .glassRow(topRadius: 5, bottomRadius: 14)
                        .opacity(notificationEnabled ? 1 : 0.4)
                        .disabled(!notificationEnabled)
                    }

                    // Status badge
                    if notificationEnabled {
                        HStack(spacing: 7) {
                            Circle()
                                .fill(Color.auroraGreen)
                                .frame(width: 7, height: 7)
                                .shadow(color: .auroraGreen.opacity(0.7), radius: 4)
                            Text("Đã lên lịch · Mỗi ngày \(timeString)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.auroraGreen.opacity(0.85))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.auroraGreen.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.auroraGreen.opacity(0.18), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        HStack(spacing: 7) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 11))
                                .foregroundStyle(.quaternary)
                            Text("Thông báo đã tắt")
                                .font(.system(size: 11))
                                .foregroundStyle(.quaternary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.04))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                // Widget section
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel("Widget")

                    VStack(spacing: 1) {
                        HStack {
                            Text("Đang hiển thị")
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Text(pinnedCards.first?.title ?? "--")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.auroraRed)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .glassRow(topRadius: 14, bottomRadius: 5)

                        Button {
                            WidgetCenter.shared.reloadAllTimelines()
                        } label: {
                            HStack {
                                Text("Làm mới widget")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("Làm mới ↺")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.auroraTeal)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .glassRow(topRadius: 5, bottomRadius: 14)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Cài đặt")
        .onAppear {
            if notificationEnabled { updateNotification() }
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

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: RealityCard.self, inMemory: true)
    .background(AuroraBackground())
    .preferredColorScheme(.dark)
}
