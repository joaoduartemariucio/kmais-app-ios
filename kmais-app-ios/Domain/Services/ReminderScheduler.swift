import Foundation

nonisolated protocol ReminderScheduler: Sendable {
    func requestAuthorization() async throws -> Bool
    func schedule(_ reminder: Reminder) async throws
    func cancel(id: UUID) async throws
    func pendingIdentifiers() async -> [UUID]
}

nonisolated struct Reminder: Identifiable, Hashable, Sendable {
    let id: UUID
    var title: String
    var body: String
    var fireDate: Date
}
