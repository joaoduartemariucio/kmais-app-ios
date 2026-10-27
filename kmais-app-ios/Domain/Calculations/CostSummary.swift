import Foundation

nonisolated struct CostSummary: Hashable, Sendable {
    let fuelCost: Decimal
    let serviceCost: Decimal
    let distance: Double

    var totalCost: Decimal { fuelCost + serviceCost }

    var costPerKilometer: Decimal? {
        guard distance > 0 else { return nil }
        return totalCost / Decimal(approximating: distance)
    }
}
