import Foundation
import SwiftData

@Model
final class FuelEntryModel {
    var id: UUID = UUID()
    var date: Date = Date.now
    var odometer: Double = 0
    var liters: Double = 0
    var pricePerLiter: Decimal = Decimal.zero
    var isFullTank: Bool = true
    var vehicle: VehicleModel?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        odometer: Double = 0,
        liters: Double = 0,
        pricePerLiter: Decimal = .zero,
        isFullTank: Bool = true,
        vehicle: VehicleModel? = nil
    ) {
        self.id = id
        self.date = date
        self.odometer = odometer
        self.liters = liters
        self.pricePerLiter = pricePerLiter
        self.isFullTank = isFullTank
        self.vehicle = vehicle
    }
}
