import Foundation

enum Odometer {
    static func current(_ samples: [OdometerSample]) -> Double? {
        samples.sortedChronologically().last?.odometer
    }

    static func samples(
        vehicle: Vehicle,
        fuel: [FuelEntry],
        services: [ServiceEntry]
    ) -> [OdometerSample] {
        [OdometerSample(date: vehicle.createdAt, odometer: vehicle.initialOdometer)]
            + fuel.map { OdometerSample(date: $0.date, odometer: $0.odometer) }
            + services.map { OdometerSample(date: $0.date, odometer: $0.odometer) }
    }
}
