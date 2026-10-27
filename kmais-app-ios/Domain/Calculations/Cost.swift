import Foundation

nonisolated enum Cost {
    static func summary(fuel: [FuelEntry], services: [ServiceEntry]) -> CostSummary {
        let odometers = fuel.map(\.odometer) + services.map(\.odometer)
        var distance = 0.0
        if let lowest = odometers.min(), let highest = odometers.max() {
            distance = max(0, highest - lowest)
        }

        return CostSummary(
            fuelCost: fuel.reduce(Decimal.zero) { $0 + $1.totalCost },
            serviceCost: services.reduce(Decimal.zero) { $0 + $1.cost },
            distance: distance
        )
    }
}
