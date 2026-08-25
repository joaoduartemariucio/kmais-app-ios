import Foundation

enum ServiceMapper {
    static func entity(_ model: ServiceEntryModel) -> ServiceEntry? {
        guard let vehicleID = model.vehicle?.id else { return nil }
        return ServiceEntry(
            id: model.id,
            vehicleID: vehicleID,
            kind: model.kind,
            date: model.date,
            odometer: model.odometer,
            cost: model.cost,
            notes: model.notes
        )
    }

    static func apply(_ entity: ServiceEntry, to model: ServiceEntryModel) {
        model.kind = entity.kind
        model.date = entity.date
        model.odometer = entity.odometer
        model.cost = entity.cost
        model.notes = entity.notes
    }

    static func entity(_ model: ServiceRuleModel) -> ServiceRule? {
        guard let vehicleID = model.vehicle?.id else { return nil }
        return ServiceRule(
            id: model.id,
            vehicleID: vehicleID,
            kind: model.kind,
            kilometerInterval: model.kilometerInterval,
            monthInterval: model.monthInterval
        )
    }

    static func apply(_ entity: ServiceRule, to model: ServiceRuleModel) {
        model.kind = entity.kind
        model.kilometerInterval = entity.kilometerInterval
        model.monthInterval = entity.monthInterval
    }
}
