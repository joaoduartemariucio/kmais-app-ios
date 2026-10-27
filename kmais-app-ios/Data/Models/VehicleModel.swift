import Foundation
import SwiftData

@Model
final class VehicleModel {
    var id: UUID = UUID()
    var name: String = ""
    var kind: VehicleKind = VehicleKind.car
    var plate: String?
    var initialOdometer: Double = 0
    var tankCapacity: Double?
    var createdAt: Date = Date.now
    var isArchived: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \FuelEntryModel.vehicle)
    var fuelEntries: [FuelEntryModel]?

    @Relationship(deleteRule: .cascade, inverse: \ServiceEntryModel.vehicle)
    var serviceEntries: [ServiceEntryModel]?

    @Relationship(deleteRule: .cascade, inverse: \ServiceRuleModel.vehicle)
    var serviceRules: [ServiceRuleModel]?

    init(
        id: UUID = UUID(),
        name: String = "",
        kind: VehicleKind = .car,
        plate: String? = nil,
        initialOdometer: Double = 0,
        tankCapacity: Double? = nil,
        createdAt: Date = .now,
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
        fuelEntries = []
        serviceEntries = []
        serviceRules = []
    }
}

extension VehicleModel {
    var fuels: [FuelEntryModel] { fuelEntries ?? [] }
    var services: [ServiceEntryModel] { serviceEntries ?? [] }
    var rules: [ServiceRuleModel] { serviceRules ?? [] }
}
