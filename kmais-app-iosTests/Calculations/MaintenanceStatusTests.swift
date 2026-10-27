import Foundation
import Testing
@testable import kmais_app_ios

@Suite("Service status")
struct MaintenanceStatusTests {
    private func due(
        kilometers: Double?,
        months: Int?,
        dueDate: Date,
        trigger: MaintenanceForecast.Trigger = .distance,
        since: OdometerSample = sample(0, 10_000)
    ) -> ServiceDue {
        ServiceDue(
            rule: rule(kilometers: kilometers, months: months),
            forecast: MaintenanceForecast(
                dueDate: dueDate,
                trigger: trigger,
                dueOdometer: kilometers.map { since.odometer + $0 },
                averageKilometersPerMonth: nil
            ),
            since: since
        )
    }

    private func status(_ due: ServiceDue, odometer: Double, now: Int) -> MaintenanceStatus {
        Maintenance.status(of: due, currentOdometer: odometer, now: day(now), calendar: utc)
    }

    @Test("halfway through both intervals is on track")
    func onTrack() {
        let result = status(due(kilometers: 10_000, months: 12, dueDate: day(200)), odometer: 15_000, now: 100)

        #expect(result.level == .onTrack)
        #expect(result.progress == 0.5)
        #expect(result.remainingKilometers == 5_000)
        #expect(result.remainingDays == 100)
    }

    @Test("a short interval uses the 300 km floor")
    func shortIntervalFloor() {
        let chain = due(kilometers: 1_000, months: nil, dueDate: day(300))

        #expect(status(chain, odometer: 10_650, now: 10).level == .onTrack)
        #expect(status(chain, odometer: 10_750, now: 10).level == .dueSoon)
    }

    @Test("a long interval is capped at 1,000 km")
    func longIntervalCap() {
        let plugs = due(kilometers: 40_000, months: nil, dueDate: day(3_000))

        #expect(status(plugs, odometer: 48_500, now: 10).level == .onTrack)
        #expect(status(plugs, odometer: 49_100, now: 10).level == .dueSoon)
    }

    @Test("the last days before the due date are due soon")
    func dueSoonByDate() {
        let oil = due(kilometers: nil, months: 12, dueDate: day(365), trigger: .calendar)

        #expect(status(oil, odometer: 10_000, now: 330).level == .onTrack)
        #expect(status(oil, odometer: 10_000, now: 340).level == .dueSoon)
    }

    @Test("reaching the due odometer is overdue")
    func overdueByDistance() {
        let result = status(due(kilometers: 10_000, months: 12, dueDate: day(300)), odometer: 21_000, now: 100)

        #expect(result.level == .overdue)
        #expect(result.progress == 1)
        #expect(result.remainingKilometers == -1_000)
    }

    @Test("passing the calendar due date is overdue")
    func overdueByCalendar() {
        let result = status(
            due(kilometers: nil, months: 1, dueDate: day(31), trigger: .calendar),
            odometer: 10_000,
            now: 40
        )

        #expect(result.level == .overdue)
        #expect(result.remainingDays == -9)
    }

    @Test("a pace-based date in the past is only due soon while the odometer is short")
    func estimatedDateIsNotOverdue() {
        let result = status(due(kilometers: 10_000, months: nil, dueDate: day(50)), odometer: 12_000, now: 60)

        #expect(result.level == .dueSoon)
        #expect(result.remainingDays == -10)
    }

    @Test("due() starts counting from the last service of that kind")
    func dueKeepsStartingPoint() {
        let vehicle = Vehicle(name: "Gol", initialOdometer: 1_000, createdAt: day(0))
        let oil = ServiceEntry(vehicleID: vehicle.id, kind: .oilChange, date: day(20), odometer: 2_000, cost: 100)

        let withService = Maintenance.due(
            rule: rule(kilometers: 5_000, months: nil),
            vehicle: vehicle,
            services: [oil],
            history: [sample(0, 1_000), sample(40, 3_000)],
            calendar: utc
        )
        let withoutService = Maintenance.due(
            rule: rule(kilometers: 5_000, months: nil),
            vehicle: vehicle,
            services: [],
            history: [sample(0, 1_000), sample(40, 3_000)],
            calendar: utc
        )

        #expect(withService?.since == sample(20, 2_000))
        #expect(withoutService?.since == sample(0, 1_000))
    }

    @Test("the status says which limit made it overdue and keeps the calendar date")
    func overdueReason() {
        let both = due(kilometers: 10_000, months: 1, dueDate: day(31), trigger: .calendar)

        let byCalendar = status(both, odometer: 12_000, now: 40)
        #expect(byCalendar.overdueBy == .calendar)
        #expect(byCalendar.calendarDueDate == day(31))

        #expect(status(both, odometer: 20_000, now: 40).overdueBy == .calendar)
        #expect(status(both, odometer: 20_000, now: 20).overdueBy == .distance)
        #expect(status(both, odometer: 12_000, now: 10).overdueBy == nil)
    }

    @Test("without a forecast date the status comes from km alone")
    func datelessStatus() {
        let chain = ServiceDue(
            rule: rule(kilometers: 1_000, months: nil),
            forecast: MaintenanceForecast(
                dueDate: nil,
                trigger: .distance,
                dueOdometer: 11_000,
                averageKilometersPerMonth: nil
            ),
            since: sample(0, 10_000)
        )

        let early = status(chain, odometer: 10_200, now: 5)
        #expect(early.level == .onTrack)
        #expect(early.remainingDays == nil)
        #expect(early.progress == 0.2)
        #expect(!early.isEstimatePassed)

        #expect(status(chain, odometer: 10_800, now: 5).level == .dueSoon)
        #expect(status(chain, odometer: 11_000, now: 5).overdueBy == .distance)
    }
}
