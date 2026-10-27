import Foundation

nonisolated struct PlannedReminder: Identifiable, Hashable, Sendable {
    let vehicle: Vehicle
    let due: ServiceDue
    let status: MaintenanceStatus
    let currentOdometer: Double
    let fireDate: Date

    var id: UUID { due.rule.id }
    var isOverdue: Bool { status.level == .overdue }
}
