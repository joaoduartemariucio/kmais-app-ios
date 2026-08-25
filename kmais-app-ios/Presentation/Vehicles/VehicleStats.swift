import Foundation

struct VehicleStats {
    let currentOdometer: Double
    let latestConsumption: ConsumptionInterval?
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
