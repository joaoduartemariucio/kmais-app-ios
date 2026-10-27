import Foundation

nonisolated struct PlannedReminder: Identifiable, Hashable, Sendable {
    let vehicle: Vehicle
    let due: ServiceDue
    let fireDate: Date
    let isOverdue: Bool

    var id: UUID { due.rule.id }
}
