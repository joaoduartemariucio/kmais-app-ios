import Foundation
import Testing
@testable import kmais_app_ios

@Suite("Service forecast")
struct MaintenanceTests {
    static let history = [sample(0, 10_000), sample(100, 15_000)]
    static let lastServiceOdometer = 10_000.0
    static let kilometersPerMonth = 50 * 365.25 / 12

    struct AverageScenario: Sendable, CustomTestStringConvertible {
        let name: String
        let samples: [OdometerSample]
        let expected: Double?

        var testDescription: String { name }
    }

    static let averageScenarios: [AverageScenario] = [
        AverageScenario(name: "empty history", samples: [], expected: nil),
        AverageScenario(name: "a single sample", samples: [sample(0, 10_000)], expected: nil),
        AverageScenario(
            name: "two samples at the same instant",
            samples: [sample(0, 10_000), sample(0, 10_500)],
            expected: nil
        ),
        AverageScenario(
            name: "a vehicle that has not moved",
            samples: [sample(0, 10_000), sample(100, 10_000)],
            expected: nil
        ),
        AverageScenario(name: "50 km per day", samples: history, expected: kilometersPerMonth),
        AverageScenario(
            name: "out-of-order samples are sorted first",
            samples: [sample(100, 15_000), sample(0, 10_000)],
            expected: kilometersPerMonth
        )
    ]

    @Test("averageKilometersPerMonth(_:) per scenario", arguments: averageScenarios)
    func average(_ scenario: AverageScenario) {
        let average = Maintenance.averageKilometersPerMonth(scenario.samples)

        switch (average, scenario.expected) {
        case let (actual?, expected?):
            #expect(abs(actual - expected) < 1e-9)
        case (nil, nil):
            break
        default:
            Issue.record("average \(String(describing: average)) != \(String(describing: scenario.expected))")
        }
    }

    private func makeForecast(
        kilometers: Double?,
        months: Int?,
        history: [OdometerSample] = MaintenanceTests.history
    ) -> MaintenanceForecast? {
        Maintenance.forecast(
            rule: rule(kilometers: kilometers, months: months),
            lastServiceDate: day(0),
            lastServiceOdometer: Self.lastServiceOdometer,
            history: history,
            calendar: utc
        )
    }

    @Test("a rule with no interval forecasts nothing")
    func emptyRule() {
        #expect(makeForecast(kilometers: nil, months: nil) == nil)
        #expect(makeForecast(kilometers: 0, months: 0) == nil)
    }

    @Test("a distance-only rule without usable history keeps its due km but has no date")
    func kilometersWithoutHistory() throws {
        let histories = [[], [sample(0, 10_000)], [sample(0, 10_000), sample(100, 10_000)]]
        for history in histories {
            let forecast = try #require(makeForecast(kilometers: 10_000, months: nil, history: history))
            #expect(forecast.dueDate == nil)
            #expect(forecast.dueOdometer == 20_000)
            #expect(forecast.trigger == .distance)
        }
    }

    @Test("distance comes due before the calendar")
    func distanceWinsFirst() throws {
        let forecast = try #require(makeForecast(kilometers: 10_000, months: 12))

        #expect(forecast.trigger == .distance)
        #expect(forecast.dueDate == day(200))
        #expect(forecast.dueOdometer == 20_000)
        #expect(try abs(#require(forecast.averageKilometersPerMonth) - Self.kilometersPerMonth) < 1e-9)
    }

    @Test("months come due before the distance")
    func calendarWinsFirst() throws {
        let forecast = try #require(makeForecast(kilometers: 30_000, months: 6))

        #expect(forecast.trigger == .calendar)
        #expect(forecast.dueDate == day(181))
        #expect(forecast.dueOdometer == 40_000)
    }

    @Test("a time-only rule has no due odometer")
    func calendarOnly() throws {
        let forecast = try #require(makeForecast(kilometers: nil, months: 6))

        #expect(forecast.trigger == .calendar)
        #expect(forecast.dueDate == day(181))
        #expect(forecast.dueOdometer == nil)
    }

    @Test("a distance-only rule projects the date from the usage pace")
    func distanceOnly() throws {
        let forecast = try #require(makeForecast(kilometers: 10_000, months: nil))

        #expect(forecast.trigger == .distance)
        #expect(forecast.dueDate == day(200))
    }

    @Test("a tie between distance and calendar resolves to distance")
    func tieBreaksToDistance() throws {
        let forecast = try #require(makeForecast(kilometers: 18_250, months: 12))

        #expect(forecast.dueDate == day(365))
        #expect(forecast.trigger == .distance)
    }

    @Test("an already overdue service returns a date in the past")
    func alreadyOverdue() throws {
        let forecast = try #require(makeForecast(kilometers: 1_000, months: 12))

        #expect(forecast.trigger == .distance)
        #expect(forecast.dueDate == day(20))
        #expect(try #require(forecast.dueDate) < day(100))
    }

    @Test("a vehicle that has not moved falls back to the time rule")
    func stationaryFallsBackToCalendar() throws {
        let forecast = try #require(
            makeForecast(
                kilometers: 10_000,
                months: 6,
                history: [sample(0, 10_000), sample(100, 10_000)]
            )
        )

        #expect(forecast.trigger == .calendar)
        #expect(forecast.dueDate == day(181))
        #expect(forecast.dueOdometer == 20_000)
        #expect(forecast.averageKilometersPerMonth == nil)
    }
}

@Suite("Next service due")
struct NextServiceDueTests {

    private static let vehicle = Vehicle(
        name: "Gol",
        initialOdometer: 10_000,
        createdAt: day(0)
    )

    private static let history = [sample(0, 10_000), sample(100, 15_000)]

    private static func rule(_ kind: ServiceKind, kilometers: Double?, months: Int?) -> ServiceRule {
        ServiceRule(
            vehicleID: vehicle.id,
            kind: kind,
            kilometerInterval: kilometers,
            monthInterval: months
        )
    }

    @Test("without rules there is nothing due")
    func noRules() {
        #expect(
            Maintenance.nextDue(
                rules: [],
                vehicle: Self.vehicle,
                services: [],
                history: Self.history,
                calendar: utc
            ) == nil
        )
    }

    @Test("with no service of that kind the baseline is the vehicle registration")
    func fallsBackToRegistration() throws {
        let due = try #require(
            Maintenance.due(
                rule: Self.rule(.oilChange, kilometers: 10_000, months: nil),
                vehicle: Self.vehicle,
                services: [],
                history: Self.history,
                calendar: utc
            )
        )

        #expect(due.forecast.dueOdometer == 20_000)
        #expect(due.forecast.dueDate == day(200))
    }

    @Test("the last service of the kind wins over the registration")
    func usesLastService() throws {
        let service = ServiceEntry(
            vehicleID: Self.vehicle.id,
            kind: .oilChange,
            date: day(50),
            odometer: 12_500,
            cost: 300
        )

        let due = try #require(
            Maintenance.due(
                rule: Self.rule(.oilChange, kilometers: 10_000, months: nil),
                vehicle: Self.vehicle,
                services: [service],
                history: Self.history,
                calendar: utc
            )
        )

        #expect(due.forecast.dueOdometer == 22_500)
    }

    @Test("a service of another kind does not move the baseline")
    func ignoresOtherKinds() throws {
        let service = ServiceEntry(
            vehicleID: Self.vehicle.id,
            kind: .tires,
            date: day(50),
            odometer: 12_500,
            cost: 300
        )

        let due = try #require(
            Maintenance.due(
                rule: Self.rule(.oilChange, kilometers: 10_000, months: nil),
                vehicle: Self.vehicle,
                services: [service],
                history: Self.history,
                calendar: utc
            )
        )

        #expect(due.forecast.dueOdometer == 20_000)
    }

    @Test("the earliest due date wins among several rules")
    func earliestWins() throws {
        let due = try #require(
            Maintenance.nextDue(
                rules: [
                    Self.rule(.oilChange, kilometers: 10_000, months: nil),
                    Self.rule(.brakes, kilometers: nil, months: 6),
                    Self.rule(.tires, kilometers: 40_000, months: nil)
                ],
                vehicle: Self.vehicle,
                services: [],
                history: Self.history,
                calendar: utc
            )
        )

        #expect(due.rule.kind == .brakes)
        #expect(due.forecast.dueDate == day(181))
    }

    @Test("a rule with no possible forecast is skipped instead of blocking the others")
    func skipsUnforecastableRule() throws {
        let due = try #require(
            Maintenance.nextDue(
                rules: [
                    Self.rule(.tires, kilometers: nil, months: nil),
                    Self.rule(.oilChange, kilometers: 10_000, months: nil)
                ],
                vehicle: Self.vehicle,
                services: [],
                history: Self.history,
                calendar: utc
            )
        )

        #expect(due.rule.kind == .oilChange)
    }

    @Test("an overdue rule beats a future one")
    func overdueWins() throws {
        let due = try #require(
            Maintenance.nextDue(
                rules: [
                    Self.rule(.oilChange, kilometers: 10_000, months: nil),
                    Self.rule(.chain, kilometers: 1_000, months: nil)
                ],
                vehicle: Self.vehicle,
                services: [],
                history: Self.history,
                calendar: utc
            )
        )

        #expect(due.rule.kind == .chain)
        #expect(try #require(due.forecast.dueDate) < day(100))
    }

    @Test("a tie on the due date resolves deterministically by kind")
    func tieResolvesByKind() throws {
        let due = try #require(
            Maintenance.nextDue(
                rules: [
                    Self.rule(.tires, kilometers: 10_000, months: nil),
                    Self.rule(.brakes, kilometers: 10_000, months: nil)
                ],
                vehicle: Self.vehicle,
                services: [],
                history: Self.history,
                calendar: utc
            )
        )

        #expect(due.rule.kind == .brakes)
    }
}
