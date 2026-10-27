import Foundation
import Testing
@testable import kmais_app_ios

@Suite("Reminder plan")
struct ReminderPlanTests {
    private static let vehicle = Vehicle(id: testVehicleID, name: "Gol", initialOdometer: 10_000, createdAt: day(0))

    private func hour(_ hour: Int, on dayOffset: Int) -> Date {
        day(dayOffset).addingTimeInterval(Double(hour) * 3_600)
    }

    private func records(
        vehicle: Vehicle = Self.vehicle,
        fuel: [FuelEntry] = [],
        services: [ServiceEntry] = [],
        rules: [ServiceRule]
    ) -> VehicleRecords {
        VehicleRecords(vehicle: vehicle, fuel: fuel, services: services, rules: rules)
    }

    @Test("fires at 9:00 on the due day when it is still ahead")
    func fireOnDueDay() {
        #expect(ReminderPlan.fireDate(for: day(10), now: hour(15, on: 2), calendar: utc) == hour(9, on: 10))
    }

    @Test("an overdue reminder fires at the next 9:00")
    func fireWhenOverdue() {
        #expect(ReminderPlan.fireDate(for: day(1), now: hour(7, on: 5), calendar: utc) == hour(9, on: 5))
        #expect(ReminderPlan.fireDate(for: day(1), now: hour(10, on: 5), calendar: utc) == hour(9, on: 6))
    }

    @Test("a calendar rule is due months after the last service of its kind")
    func calendarRule() throws {
        let rule = ServiceRule(vehicleID: testVehicleID, kind: .oilChange, monthInterval: 6)

        let planned = ReminderPlan.reminders(for: [records(rules: [rule])], now: day(1), calendar: utc)

        let reminder = try #require(planned.first)
        #expect(planned.count == 1)
        #expect(reminder.id == rule.id)
        #expect(reminder.due.forecast.trigger == .calendar)
        #expect(reminder.fireDate == utc.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: reminder.due.forecast.dueDate
        ))
        #expect(!reminder.isOverdue)
    }

    @Test("a reminder past its due date is flagged as overdue")
    func overdue() throws {
        let rule = ServiceRule(vehicleID: testVehicleID, kind: .inspection, monthInterval: 1)

        let planned = ReminderPlan.reminders(for: [records(rules: [rule])], now: day(90), calendar: utc)

        #expect(try #require(planned.first).isOverdue)
    }

    @Test("an overdue reminder repeats daily for a week, then weekly")
    func overdueBackoff() {
        #expect(ReminderPlan.overdueFireDate(since: day(0), now: hour(10, on: 3), calendar: utc) == hour(9, on: 4))
        #expect(ReminderPlan.overdueFireDate(since: day(0), now: hour(10, on: 6), calendar: utc) == hour(9, on: 7))
        #expect(ReminderPlan.overdueFireDate(since: day(0), now: hour(10, on: 7), calendar: utc) == hour(9, on: 14))
        #expect(ReminderPlan.overdueFireDate(since: day(0), now: hour(8, on: 14), calendar: utc) == hour(9, on: 14))
        #expect(ReminderPlan.overdueFireDate(since: day(0), now: hour(10, on: 14), calendar: utc) == hour(9, on: 21))
    }

    @Test("a passed pace estimate is not repeated until the service is really overdue")
    func stalePaceEstimate() {
        let rule = ServiceRule(vehicleID: testVehicleID, kind: .oilChange, kilometerInterval: 5_000)
        let fuel = [full(10, 10_500, 30), full(20, 11_000, 30)]

        #expect(ReminderPlan.reminders(for: [records(fuel: fuel, rules: [rule])], now: day(200), calendar: utc)
            .isEmpty)
    }

    @Test("a km-only rule without a pace is notified once the odometer reaches it")
    func distanceOverdueWithoutPace() throws {
        let rule = ServiceRule(vehicleID: testVehicleID, kind: .chain, kilometerInterval: 1_000)
        let fuel = [full(5, 11_200, 10)]
        let vehicle = Vehicle(id: testVehicleID, name: "CB", initialOdometer: 10_000, createdAt: day(5))

        let planned = ReminderPlan.reminders(
            for: [records(vehicle: vehicle, fuel: fuel, rules: [rule])],
            now: hour(10, on: 5),
            calendar: utc
        )

        let reminder = try #require(planned.first)
        #expect(reminder.isOverdue)
        #expect(reminder.status.overdueBy == .distance)
        #expect(reminder.currentOdometer == 11_200)
        #expect(reminder.fireDate == hour(9, on: 6))
    }

    @Test("overdue by km counts from the first reading at or past the due km")
    func overdueSinceDistance() throws {
        let rule = ServiceRule(vehicleID: testVehicleID, kind: .chain, kilometerInterval: 1_000)
        let fuel = [full(10, 10_600, 10), full(20, 11_100, 10), full(30, 11_500, 10)]

        let planned = ReminderPlan.reminders(
            for: [records(fuel: fuel, rules: [rule])],
            now: hour(10, on: 40),
            calendar: utc
        )

        let reminder = try #require(planned.first)
        #expect(ReminderPlan.overdueSince(
            due: reminder.due,
            status: reminder.status,
            history: [sample(0, 10_000), sample(10, 10_600), sample(20, 11_100), sample(30, 11_500)]
        ) == day(20))
        #expect(reminder.fireDate == hour(9, on: 41))
    }

    @Test("a distance rule without a km pace yet has nothing to schedule")
    func distanceRuleWithoutHistory() {
        let rule = ServiceRule(vehicleID: testVehicleID, kind: .tires, kilometerInterval: 20_000)

        #expect(ReminderPlan.reminders(for: [records(rules: [rule])], now: day(1), calendar: utc).isEmpty)
    }

    @Test("archived vehicles get no reminders")
    func archivedVehicle() {
        var archived = Self.vehicle
        archived.isArchived = true
        let rule = ServiceRule(vehicleID: testVehicleID, kind: .oilChange, monthInterval: 6)

        #expect(ReminderPlan.reminders(for: [records(vehicle: archived, rules: [rule])], now: day(1), calendar: utc)
            .isEmpty)
    }

    @Test("reminders come out ordered by fire date")
    func ordered() {
        let later = ServiceRule(vehicleID: testVehicleID, kind: .oilChange, monthInterval: 12)
        let sooner = ServiceRule(vehicleID: testVehicleID, kind: .inspection, monthInterval: 3)

        let planned = ReminderPlan.reminders(for: [records(rules: [later, sooner])], now: day(1), calendar: utc)

        #expect(planned.map(\.id) == [sooner.id, later.id])
    }
}
