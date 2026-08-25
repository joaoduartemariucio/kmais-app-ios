import Foundation

/// Um serviço já executado.
struct ServiceEntry: Identifiable, Hashable, Sendable, Chronological {
    let id: UUID
    let vehicleID: UUID
    var kind: ServiceKind
    var date: Date
    var odometer: Double
    var cost: Decimal
    var notes: String

    init(
        id: UUID = UUID(),
        vehicleID: UUID,
        kind: ServiceKind = .other,
        date: Date,
        odometer: Double,
        cost: Decimal,
        notes: String = ""
    ) {
        self.id = id
        self.vehicleID = vehicleID
        self.kind = kind
        self.date = date
        self.odometer = odometer
        self.cost = cost
        self.notes = notes
    }
}
