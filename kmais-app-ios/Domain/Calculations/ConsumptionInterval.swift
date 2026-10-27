import Foundation

nonisolated struct ConsumptionInterval: Hashable, Sendable {
    let startDate: Date
    let endDate: Date
    let startOdometer: Double
    let endOdometer: Double
    let liters: Double

    var distance: Double { endOdometer - startOdometer }

    var kilometersPerLiter: Double { distance / liters }
}
