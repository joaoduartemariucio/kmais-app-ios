import Foundation

struct CostSummary: Hashable, Sendable {
    let fuelCost: Decimal
    let serviceCost: Decimal
    let distance: Double

    init(fuelCost: Decimal, serviceCost: Decimal, distance: Double) {
        self.fuelCost = fuelCost
        self.serviceCost = serviceCost
        self.distance = distance
    }

    var totalCost: Decimal { fuelCost + serviceCost }

    var costPerKilometer: Decimal? {
        guard distance > 0 else { return nil }
        return totalCost / Decimal(approximating: distance)
    }
}
