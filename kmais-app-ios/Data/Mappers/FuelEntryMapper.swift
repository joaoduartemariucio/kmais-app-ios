import Foundation

enum FuelEntryMapper {
    /// - Returns: `nil` quando o registro está órfão. O schema permite
    ///   abastecimento sem veículo, mas a entidade do domínio exige o vínculo,
    ///   então um órfão simplesmente não existe para o domínio.
    static func entity(_ model: FuelEntryModel) -> FuelEntry? {
        guard let vehicleID = model.vehicle?.id else { return nil }
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
