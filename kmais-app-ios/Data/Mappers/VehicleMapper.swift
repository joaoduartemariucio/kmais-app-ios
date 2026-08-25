import Foundation

nonisolated enum VehicleMapper {
    static func entity(_ model: VehicleModel) -> Vehicle {
        Vehicle(
            id: model.id,
            name: model.name,
            kind: model.kind,
            plate: model.plate,
            initialOdometer: model.initialOdometer,
            tankCapacity: model.tankCapacity,
            createdAt: model.createdAt,
            isArchived: model.isArchived
        )
    }

    static func apply(_ entity: Vehicle, to model: VehicleModel) {
        model.name = entity.name
        model.kind = entity.kind
        model.plate = entity.plate
        model.initialOdometer = entity.initialOdometer
        model.tankCapacity = entity.tankCapacity
        model.isArchived = entity.isArchived
    }
}
