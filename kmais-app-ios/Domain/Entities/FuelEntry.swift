import Foundation

/// Um abastecimento.
///
/// Distâncias em quilômetros, volume em litros, dinheiro em `Decimal`. Este é
/// ao mesmo tempo a entidade do domínio e a entrada das funções de
/// `Calculations` — não existe um tipo separado para cálculo.
struct FuelEntry: Identifiable, Hashable, Sendable, Chronological {
    let id: UUID
    let vehicleID: UUID
    var date: Date
    var odometer: Double
    var liters: Double
    var pricePerLiter: Decimal
    /// Só um tanque cheio abre ou fecha um intervalo de consumo.
    var isFullTank: Bool

    init(
        id: UUID = UUID(),
        vehicleID: UUID,
        date: Date,
        odometer: Double,
        liters: Double,
        pricePerLiter: Decimal,
        isFullTank: Bool
    ) {
        self.id = id
        self.vehicleID = vehicleID
        self.date = date
        self.odometer = odometer
        self.liters = liters
        self.pricePerLiter = pricePerLiter
        self.isFullTank = isFullTank
    }

    var totalCost: Decimal {
        Decimal(approximating: liters) * pricePerLiter
    }
}
