import Foundation

/// As métricas de um veículo, calculadas de uma vez.
///
/// Não calcula nada: só chama `Domain/Calculations` e guarda o resultado, para
/// que a tela faça uma chamada em vez de quatro.
struct VehicleStats {
    let currentOdometer: Double
    /// Consumo do último trecho fechado entre dois tanques cheios.
    let latestConsumption: ConsumptionInterval?
    /// Média ponderada de todos os trechos, em km/l.
    let averageConsumption: Double?
    let cost: CostSummary

    init(vehicle: Vehicle, fuel: [FuelEntry], services: [ServiceEntry]) {
        let samples = Odometer.samples(vehicle: vehicle, fuel: fuel, services: services)

        currentOdometer = Odometer.current(samples) ?? vehicle.initialOdometer
        latestConsumption = Consumption.latest(from: fuel)
        averageConsumption = Consumption.average(from: fuel)
        cost = Cost.summary(fuel: fuel, services: services)
    }
}
