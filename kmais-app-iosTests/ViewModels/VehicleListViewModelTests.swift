import Foundation
import Testing
@testable import kmais_app_ios

@MainActor
@Suite("Vehicle list")
struct VehicleListViewModelTests {

    private func makeVehicle(name: String, archived: Bool = false) -> Vehicle {
        Vehicle(name: name, createdAt: day(0), isArchived: archived)
    }

    private func makeViewModel(
        scope: VehicleListViewModel.Scope = .active,
        vehicles: [Vehicle] = [],
        fuel: [FuelEntry] = [],
        services: [ServiceEntry] = [],
        failure: Error? = nil
    ) -> VehicleListViewModel {
        VehicleListViewModel(
            scope: scope,
            vehicleRepository: InMemoryVehicleRepository(vehicles: vehicles, failure: failure),
            fuelEntryRepository: InMemoryFuelEntryRepository(entries: fuel),
            serviceRepository: InMemoryServiceRepository(entries: services)
        )
    }

    @Test("loads vehicles with their stats")
    func loadsSuccessfully() async throws {
        let vehicle = makeVehicle(name: "Gol")
        let fuel = [
            FuelEntry(vehicleID: vehicle.id, date: day(0), odometer: 1_000, liters: 40, pricePerLiter: 5, isFullTank: true),
            FuelEntry(vehicleID: vehicle.id, date: day(10), odometer: 1_400, liters: 40, pricePerLiter: 5, isFullTank: true)
        ]
        let viewModel = makeViewModel(vehicles: [vehicle], fuel: fuel)

        await viewModel.load()

        guard case .loaded(let rows) = viewModel.state else {
            Issue.record("expected .loaded, got \(viewModel.state)")
            return
        }
        #expect(rows.count == 1)
        #expect(rows[0].vehicle.id == vehicle.id)
        #expect(rows[0].stats.currentOdometer == 1_400)
        #expect(rows[0].stats.latestConsumption?.kilometersPerLiter == 10)
    }

    @Test("an empty repository loads an empty list, not an error")
    func loadsEmpty() async {
        let viewModel = makeViewModel()

        await viewModel.load()

        guard case .loaded(let rows) = viewModel.state else {
            Issue.record("expected .loaded, got \(viewModel.state)")
            return
        }
        #expect(rows.isEmpty)
    }

    @Test("a repository failure surfaces as .failed instead of being swallowed")
    func surfacesFailure() async {
        let viewModel = makeViewModel(failure: RepositoryError.vehicleNotFound(UUID()))

        await viewModel.load()

        guard case .failed = viewModel.state else {
            Issue.record("expected .failed, got \(viewModel.state)")
            return
        }
    }

    @Test("the active scope hides archived vehicles")
    func activeScopeHidesArchived() async {
        let viewModel = makeViewModel(
            vehicles: [makeVehicle(name: "Gol"), makeVehicle(name: "Uno", archived: true)]
        )

        await viewModel.load()

        guard case .loaded(let rows) = viewModel.state else {
            Issue.record("expected .loaded, got \(viewModel.state)")
            return
        }
        #expect(rows.map(\.vehicle.name) == ["Gol"])
    }

    @Test("the archived scope shows only archived vehicles")
    func archivedScopeShowsArchivedOnly() async {
        let viewModel = makeViewModel(
            scope: .archived,
            vehicles: [makeVehicle(name: "Gol"), makeVehicle(name: "Uno", archived: true)]
        )

        await viewModel.load()

        guard case .loaded(let rows) = viewModel.state else {
            Issue.record("expected .loaded, got \(viewModel.state)")
            return
        }
        #expect(rows.map(\.vehicle.name) == ["Uno"])
    }

    @Test("archiving reloads and drops the vehicle from the active list")
    func archivingReloads() async {
        let vehicle = makeVehicle(name: "Gol")
        let viewModel = makeViewModel(vehicles: [vehicle])
        await viewModel.load()

        await viewModel.setArchived(true, on: vehicle)

        guard case .loaded(let rows) = viewModel.state else {
            Issue.record("expected .loaded, got \(viewModel.state)")
            return
        }
        #expect(rows.isEmpty)
    }
}
