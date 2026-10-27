import Foundation

nonisolated enum Odometer {
    static func current(_ samples: [OdometerSample]) -> Double? {
        samples.sortedChronologically().last?.odometer
    }

    static func neighbors(of date: Date, in samples: [OdometerSample]) -> OdometerNeighbors {
        let sorted = samples.sortedChronologically()
        return OdometerNeighbors(
            previous: sorted.last { $0.date <= date }?.odometer,
            next: sorted.first { $0.date > date }?.odometer
        )
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
