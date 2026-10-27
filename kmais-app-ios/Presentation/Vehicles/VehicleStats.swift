import Foundation

struct VehicleStats {
    struct DueItem: Identifiable {
        let due: ServiceDue
        let status: MaintenanceStatus

        var id: UUID { due.rule.id }

        var isEstimatePassed: Bool { status.level != .overdue && status.remainingDays < 0 }

        var relativeDue: String {
            isEstimatePassed ? String(localized: "Estimate passed") : status.remainingDays.formattedRelativeDays
        }
    }

    let currentOdometer: Double
    let latestConsumption: ConsumptionInterval?
    let averageConsumption: Double?
    let consumptionHistory: [ConsumptionInterval]
    let consumptionByEntry: [UUID: Double]
    let kilometersPerMonth: Double?
    let cost: CostSummary
    let spentThisMonth: Decimal
    let lastPricePerLiter: Decimal?
    let dues: [DueItem]

    var nextDue: DueItem? { dues.first }

    var attentionLevel: MaintenanceStatus.Level? { dues.map(\.status.level).max() }

    init(
        vehicle: Vehicle,
        fuel: [FuelEntry],
        services: [ServiceEntry],
        rules: [ServiceRule] = [],
        now: Date,
        calendar: Calendar = .current
    ) {
        let samples = Odometer.samples(vehicle: vehicle, fuel: fuel, services: services)
        let intervals = Consumption.intervals(from: fuel)
        let current = Odometer.current(samples) ?? vehicle.initialOdometer

        currentOdometer = current
        latestConsumption = intervals.last
        averageConsumption = Consumption.average(from: fuel)
        consumptionHistory = intervals
        consumptionByEntry = Self.consumptionByEntry(fuel: fuel, intervals: intervals)
        kilometersPerMonth = Maintenance.averageKilometersPerMonth(samples)
        cost = Cost.summary(fuel: fuel, services: services)
        lastPricePerLiter = fuel.sortedChronologically().last?.pricePerLiter

        let thisMonth = calendar.dateInterval(of: .month, for: now)
        spentThisMonth = fuel.filter { thisMonth?.contains($0.date) ?? false }.reduce(.zero) { $0 + $1.totalCost }
            + services.filter { thisMonth?.contains($0.date) ?? false }.reduce(.zero) { $0 + $1.cost }

        dues = rules
            .compactMap { rule in
                Maintenance.due(rule: rule, vehicle: vehicle, services: services, history: samples, calendar: calendar)
            }
            .map { due in
                DueItem(
                    due: due,
                    status: Maintenance.status(of: due, currentOdometer: current, now: now, calendar: calendar)
                )
            }
            .sorted { lhs, rhs in
                if lhs.status.level != rhs.status.level { return lhs.status.level > rhs.status.level }
                if lhs.due.forecast.dueDate != rhs.due.forecast.dueDate {
                    return lhs.due.forecast.dueDate < rhs.due.forecast.dueDate
                }
                return lhs.due.rule.kind.rawValue < rhs.due.rule.kind.rawValue
            }
    }

    private static func consumptionByEntry(fuel: [FuelEntry], intervals: [ConsumptionInterval]) -> [UUID: Double] {
        var result: [UUID: Double] = [:]
        for interval in intervals {
            let closing = fuel.first {
                $0.isFullTank && $0.date == interval.endDate && $0.odometer == interval.endOdometer
            }
            if let closing { result[closing.id] = interval.kilometersPerLiter }
        }
        return result
    }
}
