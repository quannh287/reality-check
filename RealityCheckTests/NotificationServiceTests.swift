import Testing
import Foundation
import UserNotifications
@testable import RealityCheck

@Suite("NotificationService")
struct NotificationServiceTests {

    @Test("Notification content includes card value and context")
    func notificationContent() {
        let card = RealityCard(
            title: "Runway", type: .formula, formula: .divide,
            inputA: 30_000_000, inputB: 15_000_000,
            unit: "tháng", contextLine: "còn sống được nếu nghỉ việc"
        )
        let content = NotificationService.buildContent(for: card)
        #expect(content.title == "Reality Check")
        #expect(content.body.contains("2"))
        #expect(content.body.contains("còn sống được nếu nghỉ việc"))
    }

    @Test("Notification content for nil card shows prompt")
    func notificationContentNoCard() {
        let content = NotificationService.buildContent(for: nil)
        #expect(content.body.contains("Reality Card"))
    }

    @Test("Trigger is daily at specified hour and minute")
    func dailyTrigger() {
        let trigger = NotificationService.buildDailyTrigger(hour: 8, minute: 30)
        #expect(trigger.dateComponents.hour == 8)
        #expect(trigger.dateComponents.minute == 30)
        #expect(trigger.repeats == true)
    }
}
