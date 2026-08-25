import Foundation

nonisolated struct Vehicle: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var kind: VehicleKind
    var plate: String?
    var initialOdometer: Double
    var tankCapacity: Double?
    var createdAt: Date
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        name: String,
        kind: VehicleKind = .car,
        plate: String? = nil,
        initialOdometer: Double = 0,
        tankCapacity: Double? = nil,
        createdAt: Date,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.plate = plate
        self.initialOdometer = initialOdometer
        self.tankCapacity = tankCapacity
        self.createdAt = createdAt
        self.isArchived = isArchived
    }
}
