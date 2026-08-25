import Foundation

/// Agendamento de lembretes de revisão.
///
/// Protocolo só: nenhuma tela usa isto ainda. Existe para que a previsão de
/// revisão já tenha para onde ir sem que o domínio conheça `UserNotifications`.
protocol ReminderScheduler: Sendable {
    func requestAuthorization() async throws -> Bool
    func schedule(_ reminder: Reminder) async throws
    func cancel(id: UUID) async throws
    func pendingIdentifiers() async -> [UUID]
}

/// Um lembrete agendado, identificado pela regra que o originou.
struct Reminder: Identifiable, Hashable, Sendable {
    let id: UUID
    var title: String
    var body: String
    var fireDate: Date

    init(id: UUID, title: String, body: String, fireDate: Date) {
        self.id = id
        self.title = title
        self.body = body
        self.fireDate = fireDate
    }
}
