import Foundation
import Testing
@testable import kmais_app_ios

@Suite("Vehicle stats and timeline")
struct VehicleStatsTests {
    private static let vehicle = Vehicle(id: testVehicleID, name: "Gol", initialOdometer: 1_000, createdAt: day(0))

    private func stats(
        fuel: [FuelEntry] = [],
        services: [ServiceEntry] = [],
        rules: [ServiceRule] = [],
        now: Int = 45
    ) -> VehicleStats {
        VehicleStats(
            vehicle: Self.vehicle,
            fuel: fuel,
            services: services,
            rules: rules,
            now: day(now),
            calendar: utc
        )
    }

    @Test("km/L is attached to the fill-up that closes each interval")
    func consumptionByEntry() {
        let first = full(1, 1_000, 40)
        let middle = partial(10, 1_200, 10)
        let closing = full(20, 1_500, 30, price: 6)

        let result = stats(fuel: [first, middle, closing])

        #expect(result.consumptionByEntry == [closing.id: 500.0 / 40])
        #expect(result.consumptionHistory.count == 1)
        #expect(result.lastPricePerLiter == 6)
    }

    @Test("spending this month counts only records in the current calendar month")
    func spentThisMonth() {
        let result = stats(
            fuel: [full(10, 1_100, 10), full(35, 1_400, 10)],
            services: [service(40, 1_450, 120), service(5, 1_050, 999)],
            now: 45
        )

        #expect(NSDecimalNumber(decimal: result.spentThisMonth).doubleValue == 170)
    }

    @Test("dues are sorted by urgency, the most urgent first")
    func duesSortedByUrgency() {
        let relaxed = ServiceRule(vehicleID: testVehicleID, kind: .airFilter, kilometerInterval: 20_000)
        let urgent = ServiceRule(vehicleID: testVehicleID, kind: .chain, kilometerInterval: 600)

        let result = stats(fuel: [full(1, 1_000, 40), full(40, 1_500, 30)], rules: [relaxed, urgent])

        #expect(result.dues.map(\.due.rule.kind) == [.chain, .airFilter])
        #expect(result.nextDue?.due.rule.kind == .chain)
        #expect(result.attentionLevel == .dueSoon)
        #expect(stats().attentionLevel == nil)
    }

    @Test("a passed pace estimate is not shown as days late")
    func estimatePassed() {
        let due = ServiceDue(
            rule: rule(kilometers: 10_000, months: nil),
            forecast: MaintenanceForecast(
                dueDate: day(10),
                trigger: .distance,
                dueOdometer: 11_000,
                averageKilometersPerMonth: nil
            ),
            since: sample(0, 1_000)
        )
        let passed = VehicleStats.DueItem(
            due: due,
            status: MaintenanceStatus(level: .dueSoon, progress: 1, remainingKilometers: 500, remainingDays: -5)
        )
        let overdue = VehicleStats.DueItem(
            due: due,
            status: MaintenanceStatus(level: .overdue, progress: 1, remainingKilometers: -5, remainingDays: -5)
        )

        #expect(passed.isEstimatePassed)
        #expect(passed.relativeDue == String(localized: "Estimate passed"))
        #expect(!overdue.isEstimatePassed)
        #expect(overdue.relativeDue == (-5).formattedRelativeDays)
    }

    @Test("sections can be filtered by record type and know their total")
    func filterSections() {
        let sections = VehicleTimeline.sections(
            fuel: [full(1, 1_000, 10)],
            services: [service(2, 1_100, 80)],
            calendar: utc
        )

        #expect(sections.count == 1)
        #expect(sections[0].total == 130)
        #expect(sections[0].filtered(by: .fuel)?.items.count == 1)
        #expect(sections[0].filtered(by: .service)?.total == 80)
        #expect(sections[0].filtered(by: .all)?.items.count == 2)

        let fuelOnly = VehicleTimeline.sections(fuel: [full(1, 1_000, 10)], services: [], calendar: utc)
        #expect(fuelOnly[0].filtered(by: .service) == nil)
    }

    @Test("monthly spending fills months without records with zero")
    func spendingFillsGaps() {
        let sections = VehicleTimeline.sections(
            fuel: [full(1, 1_000, 10)],
            services: [service(70, 1_500, 200)],
            calendar: utc
        )

        let months = VehicleTimeline.spending(sections, months: 3, endingAt: day(75), calendar: utc)

        #expect(months.count == 3)
        #expect(months.map(\.fuel) == [50, 0, 0])
        #expect(months.map(\.service) == [0, 0, 200])
        #expect(months.last?.total == 200)
        #expect(VehicleTimeline.spending(sections, months: 0, endingAt: day(75), calendar: utc).isEmpty)
    }

    @Test("every filter and status level has its own label, color and symbol")
    func displayValues() {
        let levels: [MaintenanceStatus.Level] = [.onTrack, .dueSoon, .overdue]
        #expect(Set(levels.map { String(localized: $0.label) }).count == 3)
        #expect(Set(levels.map(\.symbolName)).count == 3)
        #expect(Set(levels.map(\.color)).count == 3)
        #expect(Set(VehicleTimeline.Filter.allCases.map { String(localized: $0.label) }).count == 3)
        #expect(MaintenanceStatus.Level.onTrack < .overdue)
    }

    @Test("display formats include their units")
    func formats() {
        #expect(1_200.0.formattedKilometersPerMonth.contains("1"))
        #expect(500.0.formattedRemainingKilometers != (-500.0).formattedRemainingKilometers)
        #expect((-500.0).formattedRemainingKilometers.contains("500"))
        #expect(Decimal(1).formattedPerKilometer.hasSuffix("/km"))
        #expect(Decimal(6).formattedPerLiter.hasSuffix("/L"))
        #expect(3.formattedRelativeDays != (-3).formattedRelativeDays)
        #expect(!day(0).formattedShortMonth.isEmpty)
    }
}
