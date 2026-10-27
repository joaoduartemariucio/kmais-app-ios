import Foundation
import Testing
@testable import kmais_app_ios

@MainActor
@Suite("Service reminder sync")
struct ServiceReminderSyncTests {
    private nonisolated static let vehicle = Vehicle(
        id: testVehicleID,
        name: "Gol",
        initialOdometer: 10_000,
        createdAt: day(0)
    )
    private nonisolated static let oilRule = ServiceRule(vehicleID: testVehicleID, kind: .oilChange, monthInterval: 6)

    private func makeSync(
        vehicles: [Vehicle] = [vehicle],
        rules: [ServiceRule] = [oilRule],
        scheduler: FakeReminderScheduler = FakeReminderScheduler(),
        vehicleFailure: Error? = nil
    ) -> ServiceReminderSync {
        ServiceReminderSync(
            vehicleRepository: InMemoryVehicleRepository(vehicles: vehicles, failure: vehicleFailure),
            fuelEntryRepository: InMemoryFuelEntryRepository(),
            serviceRepository: InMemoryServiceRepository(rules: rules),
            scheduler: scheduler,
            dateProvider: FixedDateProvider(now: day(1))
        )
    }

    private func stale(_ id: UUID = UUID()) -> Reminder {
        Reminder(id: id, title: "old", body: "old", fireDate: day(2))
    }

    @Test("schedules one reminder per rule with a known due date")
    func schedulesRules() async {
        let scheduler = FakeReminderScheduler()

        await makeSync(scheduler: scheduler).sync()

        let scheduled = await scheduler.scheduled
        #expect(scheduled.keys.sorted { $0.uuidString < $1.uuidString } == [Self.oilRule.id])
        #expect(scheduled[Self.oilRule.id]?.title.hasPrefix("Gol: ") == true)
        #expect(scheduled[Self.oilRule.id]?.body.isEmpty == false)
        #expect(await scheduler.authorizationRequests == 1)
    }

    @Test("cancels reminders whose rule no longer applies")
    func cancelsStale() async {
        let leftover = stale()
        let scheduler = FakeReminderScheduler(pending: [leftover])

        await makeSync(scheduler: scheduler).sync()

        let ids = await scheduler.scheduled.keys
        #expect(!ids.contains(leftover.id))
        #expect(ids.contains(Self.oilRule.id))
    }

    @Test("without anything to schedule, it cancels and never asks for permission")
    func nothingToSchedule() async {
        let scheduler = FakeReminderScheduler(pending: [stale()])

        await makeSync(rules: [], scheduler: scheduler).sync()

        #expect(await scheduler.scheduled.isEmpty)
        #expect(await scheduler.authorizationRequests == 0)
    }

    @Test("when notifications are denied, nothing is scheduled")
    func denied() async {
        let scheduler = FakeReminderScheduler(isAuthorized: false)

        await makeSync(scheduler: scheduler).sync()

        #expect(await scheduler.scheduled.isEmpty)
    }

    @Test("a repository failure leaves pending reminders untouched")
    func failureKeepsPending() async {
        let pending = stale(Self.oilRule.id)
        let scheduler = FakeReminderScheduler(pending: [pending])

        await makeSync(scheduler: scheduler, vehicleFailure: RepositoryError.vehicleNotFound(testVehicleID)).sync()

        #expect(await scheduler.scheduled == [pending.id: pending])
    }

    private func planned(
        dueDate: Date?,
        trigger: MaintenanceForecast.Trigger,
        dueOdometer: Double?,
        overdueBy: MaintenanceForecast.Trigger? = nil
    ) -> PlannedReminder {
        PlannedReminder(
            vehicle: Self.vehicle,
            due: ServiceDue(
                rule: Self.oilRule,
                forecast: MaintenanceForecast(
                    dueDate: dueDate,
                    trigger: trigger,
                    dueOdometer: dueOdometer,
                    averageKilometersPerMonth: nil
                ),
                since: sample(0, 10_000)
            ),
            status: MaintenanceStatus(
                level: overdueBy == nil ? .onTrack : .overdue,
                progress: 0.5,
                remainingKilometers: nil,
                remainingDays: nil,
                overdueBy: overdueBy,
                calendarDueDate: day(8)
            ),
            currentOdometer: 21_234,
            fireDate: day(10)
        )
    }

    @Test("the body says whether the service is overdue by km or date, or due by distance or date")
    func bodies() {
        let byDate = ServiceReminderSync.reminder(for: planned(dueDate: day(10), trigger: .calendar, dueOdometer: nil))
        let byDistance = ServiceReminderSync.reminder(
            for: planned(dueDate: day(10), trigger: .distance, dueOdometer: 20_000)
        )
        let overdueByDate = ServiceReminderSync.reminder(
            for: planned(dueDate: day(10), trigger: .calendar, dueOdometer: nil, overdueBy: .calendar)
        )
        let overdueByDistance = ServiceReminderSync.reminder(
            for: planned(dueDate: nil, trigger: .distance, dueOdometer: 20_000, overdueBy: .distance)
        )
        let dateless = ServiceReminderSync.reminder(for: planned(dueDate: nil, trigger: .distance, dueOdometer: 20_000))

        #expect(byDate.id == Self.oilRule.id)
        #expect(byDate.fireDate == day(10))
        #expect(byDate.title.contains(Self.vehicle.name))
        #expect(Set([byDate, byDistance, overdueByDate, overdueByDistance, dateless].map(\.body)).count == 5)
        #expect(byDistance.body.contains(20_000.0.formattedKilometers()))
        #expect(overdueByDistance.body.contains(21_234.0.formattedKilometers()))
        #expect(overdueByDate.body.contains(day(8).formattedFullDate))
    }

    @Test("loading the list and the detail syncs reminders")
    func viewModelsSync() async throws {
        let scheduler = FakeReminderScheduler()
        let sync = makeSync(scheduler: scheduler)
        let list = VehicleListViewModel(
            scope: .active,
            vehicleRepository: InMemoryVehicleRepository(vehicles: [Self.vehicle]),
            fuelEntryRepository: InMemoryFuelEntryRepository(),
            serviceRepository: InMemoryServiceRepository(),
            dateProvider: FixedDateProvider(now: day(30)),
            reminders: sync
        )

        await list.load()
        #expect(await scheduler.scheduled.count == 1)

        try await scheduler.cancel(id: Self.oilRule.id)
        let detail = VehicleDetailViewModel(
            vehicle: Self.vehicle,
            fuelEntryRepository: InMemoryFuelEntryRepository(),
            serviceRepository: InMemoryServiceRepository(),
            dateProvider: FixedDateProvider(now: day(1)),
            reminders: sync
        )

        await detail.load()
        #expect(await scheduler.scheduled.count == 1)
    }
}
