import Foundation

struct ConsumptionInterval: Hashable, Sendable {
    let startDate: Date
    let endDate: Date
    let startOdometer: Double
    let endOdometer: Double
    let liters: Double

    init(
        startDate: Date,
        endDate: Date,
        startOdometer: Double,
        endOdometer: Double,
        liters: Double
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.startOdometer = startOdometer
        self.endOdometer = endOdometer
        self.liters = liters
    }

    var distance: Double { endOdometer - startOdometer }

    var kilometersPerLiter: Double { distance / liters }
}
