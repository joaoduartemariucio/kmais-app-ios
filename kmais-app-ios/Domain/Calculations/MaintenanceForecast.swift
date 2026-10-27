import Foundation

nonisolated struct MaintenanceForecast: Hashable, Sendable {
    enum Trigger: Hashable, Sendable {
        case distance
        case calendar
    }

    let dueDate: Date
    let trigger: Trigger
    let dueOdometer: Double?
    let averageKilometersPerMonth: Double?
}
