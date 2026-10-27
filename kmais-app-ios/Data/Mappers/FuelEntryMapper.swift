import Foundation

nonisolated enum FuelEntryMapper {
    static func entity(_ model: FuelEntryModel) -> FuelEntry? {
        guard let vehicleID = model.vehicle?.id else {
            DataLog.orphanDiscarded(type: "FuelEntryModel", id: model.id)
            return nil
        }
        return FuelEntry(
            id: model.id,
            vehicleID: vehicleID,
            date: model.date,
            odometer: model.odometer,
            liters: model.liters,
            pricePerLiter: model.pricePerLiter,
            isFullTank: model.isFullTank
        )
    }

    static func apply(_ entity: FuelEntry, to model: FuelEntryModel) {
        model.date = entity.date
        model.odometer = entity.odometer
        model.liters = entity.liters
        model.pricePerLiter = entity.pricePerLiter
        model.isFullTank = entity.isFullTank
    }
}
