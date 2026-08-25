import Foundation
import UserNotifications

/// `ReminderScheduler` sobre `UserNotifications`.
///
/// Nenhuma tela agenda nada ainda: isto existe para que a camada de domínio já
/// tenha uma implementação real por trás do protocolo quando os lembretes
/// entrarem.
struct UserNotificationReminderScheduler: ReminderScheduler {
    private var center: UNUserNotificationCenter { .current() }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func schedule(_ reminder: Reminder) async throws {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminder.fireDate
        )
        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )

        try await center.add(request)
    }

    func cancel(id: UUID) async throws {
        center.removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }

    func pendingIdentifiers() async -> [UUID] {
        await center.pendingNotificationRequests().compactMap { UUID(uuidString: $0.identifier) }
    }
}
