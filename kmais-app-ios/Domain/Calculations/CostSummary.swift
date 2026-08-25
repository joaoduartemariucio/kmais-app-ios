import Foundation

/// Gastos e distância de um período.
struct CostSummary: Hashable, Sendable {
    let fuelCost: Decimal
    let serviceCost: Decimal
    /// Distância coberta pelo período: maior odômetro menos o menor, entre
    /// todos os registros considerados. Pode ser zero.
    let distance: Double

    init(fuelCost: Decimal, serviceCost: Decimal, distance: Double) {
        self.fuelCost = fuelCost
        self.serviceCost = serviceCost
        self.distance = distance
    }

    var totalCost: Decimal { fuelCost + serviceCost }

    /// `nil` quando não há distância para dividir.
    ///
    /// Só o custo por km depende da distância; os totais continuam conhecidos
    /// mesmo com um registro único, e por isso não são opcionais.
    var costPerKilometer: Decimal? {
        guard distance > 0 else { return nil }
        return totalCost / Decimal(approximating: distance)
    }
}
