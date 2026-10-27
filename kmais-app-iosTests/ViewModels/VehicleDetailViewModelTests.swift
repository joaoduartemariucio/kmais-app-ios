import Foundation
import Testing
@testable import kmais_app_ios

@MainActor
@Suite("Vehicle detail")
struct VehicleDetailViewModelTests {

    private static let vehicle = Vehicle(
        name: "Gol",
        initialOdometer: 1_000,
        createdAt: day(0)
    )

    private static func fuel(_ dayOffset: Int, _ odometer: Double) -> FuelEntry {
        FuelEntry(
            vehicleID: vehicle.id,
            date: day(dayOffset),
            odometer: odometer,
            liters: 40,
            pricePerLiter: 5,
            isFullTank: true
        )
    }

    private func makeViewModel(
        fuel: [FuelEntry] = [],
        services: [ServiceEntry] = [],
        rules: [ServiceRule] = [],
        fuelFailure: Error? = nil
    ) -> VehicleDetailViewModel {
        VehicleDetailViewModel(
            vehicle: Self.vehicle,
            fuelEntryRepository: InMemoryFuelEntryRepository(entries: fuel, failure: fuelFailure),
            serviceRepository: InMemoryServiceRepository(entries: services, rules: rules),
            dateProvider: FixedDateProvider(now: day(120))
        )
    }

    @Test("loads stats, timeline and rules together")
    func loadsSuccessfully() async {
        let viewModel = makeViewModel(
            fuel: [Self.fuel(1, 1_000), Self.fuel(40, 1_400)],
            services: [
                ServiceEntry(
                    vehicleID: Self.vehicle.id,
                    kind: .oilChange,
                    date: day(20),
                    odometer: 1_200,
                    cost: 300
                )
            ],
            rules: [
                ServiceRule(
                    vehicleID: Self.vehicle.id,
                    kind: .oilChange,
                    kilometerInterval: 10_000,
                    monthInterval: 12
                )
            ]
        )

        await viewModel.load()

        guard case let .loaded(content) = viewModel.state else {
            Issue.record("expected .loaded, got \(viewModel.state)")
            return
        }
        #expect(content.stats.currentOdometer == 1_400)
        #expect(content.stats.cost.totalCost == 700)
        #expect(content.rules.count == 1)
        #expect(content.stats.nextDue != nil)
        #expect(content.sections.flatMap(\.items).count == 3)
    }

    @Test("a vehicle without history loads with empty sections, not an error")
    func loadsEmpty() async {
        let viewModel = makeViewModel()

        await viewModel.load()

        guard case let .loaded(content) = viewModel.state else {
            Issue.record("expected .loaded, got \(viewModel.state)")
            return
        }
        #expect(content.sections.isEmpty)
        #expect(content.stats.currentOdometer == 1_000)
        #expect(content.stats.nextDue == nil)
    }

    @Test("a repository failure surfaces as .failed instead of being swallowed")
    func surfacesFailure() async {
        let viewModel = makeViewModel(fuelFailure: RepositoryError.entryNotFound(UUID()))

        await viewModel.load()

        guard case .failed = viewModel.state else {
            Issue.record("expected .failed, got \(viewModel.state)")
            return
        }
    }

    @Test("history is grouped by month, most recent first")
    func groupsByMonth() async {
        let viewModel = makeViewModel(fuel: [Self.fuel(1, 1_000), Self.fuel(40, 1_400)])

        await viewModel.load()

        guard case let .loaded(content) = viewModel.state else {
            Issue.record("expected .loaded, got \(viewModel.state)")
            return
        }
        #expect(content.sections.count == 2)
        #expect(content.sections[0].month > content.sections[1].month)
    }

    @Test("rules are exposed once loaded and empty before")
    func exposesRules() async {
        let rule = ServiceRule(vehicleID: Self.vehicle.id, kind: .oilChange, kilometerInterval: 10_000)
        let viewModel = makeViewModel(rules: [rule])
        #expect(viewModel.rules.isEmpty)

        await viewModel.load()

        #expect(viewModel.rules == [rule])
    }

    @Test("timeline items expose the odometer of fuel and service entries")
    func timelineItemOdometer() {
        let fuelItem = VehicleTimeline.Item.fuel(Self.fuel(1, 1_000))
        let serviceItem = VehicleTimeline.Item.service(
            ServiceEntry(vehicleID: Self.vehicle.id, date: day(2), odometer: 1_100, cost: 50)
        )

        #expect(fuelItem.odometer == 1_000)
        #expect(serviceItem.odometer == 1_100)
    }

    @Test("odometer readings excluding an entry ignore that entry")
    func odometerReadingsExcluding() async {
        let latest = Self.fuel(40, 1_400)
        let viewModel = makeViewModel(fuel: [Self.fuel(1, 1_000), latest])
        await viewModel.load()

        #expect(Odometer.current(viewModel.odometerReadings()) == 1_400)
        #expect(Odometer.current(viewModel.odometerReadings(excluding: .fuel(latest))) == 1_000)
    }

    @Test("deleting an entry reloads without it")
    func deleteReloads() async {
        let doomed = Self.fuel(40, 1_400)
        let viewModel = makeViewModel(fuel: [Self.fuel(1, 1_000), doomed])
        await viewModel.load()

        await viewModel.delete(.fuel(doomed))

        guard case let .loaded(content) = viewModel.state else {
            Issue.record("expected .loaded, got \(viewModel.state)")
            return
        }
        #expect(content.sections.flatMap(\.items).count == 1)
        #expect(content.stats.currentOdometer == 1_000)
    }

    @Test("the history filter hides the other record type and drops empty months")
    func filtersHistory() async {
        let viewModel = makeViewModel(
            fuel: [Self.fuel(1, 1_000), Self.fuel(40, 1_400)],
            services: [
                ServiceEntry(vehicleID: Self.vehicle.id, kind: .oilChange, date: day(2), odometer: 1_050, cost: 300)
            ]
        )
        #expect(viewModel.visibleSections.isEmpty)
        #expect(!viewModel.hasHistory)
        #expect(viewModel.lastPricePerLiter == nil)

        await viewModel.load()

        #expect(viewModel.hasHistory)
        #expect(viewModel.lastPricePerLiter == 5)
        #expect(viewModel.visibleSections.flatMap(\.items).count == 3)

        viewModel.filter = .service
        #expect(viewModel.visibleSections.count == 1)
        #expect(viewModel.visibleSections.flatMap(\.items).count == 1)

        viewModel.filter = .fuel
        #expect(viewModel.visibleSections.flatMap(\.items).count == 2)
    }

    @Test("spending covers the last six months")
    func spendingMonths() async {
        let viewModel = makeViewModel(fuel: [Self.fuel(100, 1_400)])

        await viewModel.load()

        guard case let .loaded(content) = viewModel.state else {
            Issue.record("expected .loaded, got \(viewModel.state)")
            return
        }
        #expect(content.spending.count == VehicleDetailViewModel.spendingMonths)
        #expect(content.spending.reduce(Decimal.zero) { $0 + $1.total } == 200)
    }
}
