import Foundation

nonisolated struct FuelEntry: Identifiable, Hashable, Sendable, Chronological {
    let id: UUID
    let vehicleID: UUID
    var date: Date
    var odometer: Double
    var liters: Double
    var pricePerLiter: Decimal
    var isFullTank: Bool

    init(
        id: UUID = UUID(),
        vehicleID: UUID,
        date: Date,
        odometer: Double,
        liters: Double,
        pricePerLiter: Decimal,
        isFullTank: Bool
    ) {
        self.id = id
        self.vehicleID = vehicleID
        self.date = date
        self.odometer = odometer
        self.liters = liters
        self.pricePerLiter = pricePerLiter
        self.isFullTank = isFullTank
    }

    var totalCost: Decimal {
        Decimal(approximating: liters) * pricePerLiter
    }
}
