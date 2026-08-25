import Foundation

/// Gastos por período.
enum Cost {

    /// Consolida combustível e serviços de um período.
    ///
    /// O período é definido pelos arrays recebidos — filtre por data antes de
    /// chamar. A distância vem do intervalo de odômetro dos próprios registros.
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
