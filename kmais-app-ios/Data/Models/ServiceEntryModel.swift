import Foundation
import SwiftData

@Model
final class ServiceEntryModel {
    var id: UUID = UUID()
    var kind: ServiceKind = ServiceKind.other
    var date: Date = Date.now
    var odometer: Double = 0
    var cost: Decimal = Decimal.zero
    var notes: String = ""
    var vehicle: VehicleModel?

    init(
        id: UUID = UUID(),
        kind: ServiceKind = .other,
        date: Date = .now,
        odometer: Double = 0,
        cost: Decimal = .zero,
        notes: String = "",
        vehicle: VehicleModel? = nil
    ) {
        self.id = id
        self.kind = kind
        self.date = date
        self.odometer = odometer
        self.cost = cost
        self.notes = notes
        self.vehicle = vehicle
    }
}
