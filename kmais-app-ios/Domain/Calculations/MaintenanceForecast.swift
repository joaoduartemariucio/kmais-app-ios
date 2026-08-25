import Foundation

/// Quando uma regra de manutenção vence.
struct MaintenanceForecast: Hashable, Sendable {
    enum Trigger: Hashable, Sendable {
        /// Vence primeiro pela quilometragem projetada.
        case distance
        /// Vence primeiro pelo calendário.
        case calendar
    }

    /// A data estimada de vencimento. Pode estar no passado — quem compara com
    /// "hoje" é quem chama.
    let dueDate: Date
    let trigger: Trigger
    /// O odômetro em que a regra vence. `nil` quando a regra é só por tempo.
    let dueOdometer: Double?
    /// A média usada para projetar a data por distância. `nil` quando não deu
    /// para estimar — histórico curto demais ou veículo parado.
    let averageKilometersPerMonth: Double?

    init(
        dueDate: Date,
        trigger: Trigger,
        dueOdometer: Double?,
        averageKilometersPerMonth: Double?
    ) {
        self.dueDate = dueDate
        self.trigger = trigger
        self.dueOdometer = dueOdometer
        self.averageKilometersPerMonth = averageKilometersPerMonth
    }
}
