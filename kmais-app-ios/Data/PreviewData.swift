import Foundation
import SwiftData

@MainActor
enum PreviewData {
    static let car = Vehicle(
        id: UUID(uuidString: "00000000-0000-0000-0000-0000000000C1")!,
        name: "Gol 1.6",
        kind: .car,
        plate: "ABC1D23",
        initialOdometer: 38_000,
        tankCapacity: 55,
        createdAt: date(monthsAgo: 5)
    )

    static let motorcycle = Vehicle(
        id: UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!,
        name: "CB 500",
        kind: .motorcycle,
        plate: "XYZ9K87",
        initialOdometer: 12_000,
        tankCapacity: 17,
        createdAt: date(monthsAgo: 4)
    )

    static func container() -> ModelContainer {
        do {
            let container = try KmaisSchema.container(inMemory: true)
            seed(into: container.mainContext)
            return container
        } catch {
            fatalError("Preview container failed: \(error)")
        }
    }

    private static let referenceNow = Date(timeIntervalSinceReferenceDate: 806_000_000)

    private static func date(monthsAgo: Int, plusDays days: Int = 0) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let base = calendar.date(byAdding: .month, value: -monthsAgo, to: referenceNow) ?? referenceNow
        return calendar.date(byAdding: .day, value: days, to: base) ?? base
    }

    private static func seed(into context: ModelContext) {
        seedCar(into: context)
        seedMotorcycle(into: context)
        try? context.save()
    }

    private static func model(for vehicle: Vehicle) -> VehicleModel {
        VehicleModel(
            id: vehicle.id,
            name: vehicle.name,
            kind: vehicle.kind,
            plate: vehicle.plate,
            initialOdometer: vehicle.initialOdometer,
            tankCapacity: vehicle.tankCapacity,
            createdAt: vehicle.createdAt
        )
    }

    private struct Fill {
        let monthsAgo: Int
        let days: Int
        let odometer: Double
        let liters: Double
        let price: String
        let full: Bool
    }

    private static func insert(_ fill: Fill, for vehicle: VehicleModel, into context: ModelContext) {
        context.insert(
            FuelEntryModel(
                date: date(monthsAgo: fill.monthsAgo, plusDays: fill.days),
                odometer: fill.odometer,
                liters: fill.liters,
                pricePerLiter: Decimal(string: fill.price)!,
                isFullTank: fill.full,
                vehicle: vehicle
            )
        )
    }

    private static func seedCar(into context: ModelContext) {
        let vehicle = model(for: car)
        context.insert(vehicle)

        var odometer = car.initialOdometer
        for month in stride(from: 4, through: 0, by: -1) {
            odometer += 620
            insert(
                Fill(monthsAgo: month, days: 3, odometer: odometer, liters: 42, price: "5.89", full: true),
                for: vehicle,
                into: context
            )
            odometer += 180
            insert(
                Fill(monthsAgo: month, days: 17, odometer: odometer, liters: 15, price: "5.95", full: false),
                for: vehicle,
                into: context
            )
        }

        context.insert(
            ServiceEntryModel(
                kind: .oilChange,
                date: date(monthsAgo: 3),
                odometer: car.initialOdometer + 1_500,
                cost: Decimal(string: "320.00")!,
                notes: "Óleo sintético 5W30",
                vehicle: vehicle
            )
        )
        context.insert(
            ServiceRuleModel(
                kind: .oilChange,
                kilometerInterval: 10_000,
                monthInterval: 12,
                vehicle: vehicle
            )
        )
    }

    private static func seedMotorcycle(into context: ModelContext) {
        let vehicle = model(for: motorcycle)
        context.insert(vehicle)

        var odometer = motorcycle.initialOdometer
        for month in stride(from: 3, through: 0, by: -1) {
            odometer += 340
            insert(
                Fill(monthsAgo: month, days: 8, odometer: odometer, liters: 13, price: "5.79", full: true),
                for: vehicle,
                into: context
            )
        }

        context.insert(
            ServiceRuleModel(
                kind: .chain,
                kilometerInterval: 1_000,
                monthInterval: nil,
                vehicle: vehicle
            )
        )
    }
}

extension AppDependencies {
    static var preview: AppDependencies {
        AppDependencies(modelContainer: PreviewData.container())
    }
}
