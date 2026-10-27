import Foundation
import Testing
@testable import kmais_app_ios

@MainActor
@Suite("Vehicle form")
struct VehicleFormViewModelTests {
    private func makeViewModel(
        mode: VehicleFormViewModel.Mode = .create,
        existingRules: [ServiceRule] = [],
        vehicleRepository: InMemoryVehicleRepository = InMemoryVehicleRepository(),
        serviceRepository: InMemoryServiceRepository = InMemoryServiceRepository()
    ) -> VehicleFormViewModel {
        VehicleFormViewModel(
            mode: mode,
            existingRules: existingRules,
            vehicleRepository: vehicleRepository,
            serviceRepository: serviceRepository,
            dateProvider: FixedDateProvider(now: day(30))
        )
    }

    @Test("a new vehicle needs a name")
    func nameRequired() {
        let viewModel = makeViewModel()
        viewModel.name = "   "

        #expect(viewModel.issues == [.nameRequired])
        #expect(!viewModel.canSave)
    }

    @Test("a reminder needs a distance or a time interval")
    func ruleNeedsInterval() {
        let viewModel = makeViewModel()
        viewModel.name = "Gol"
        viewModel.addRule()

        #expect(viewModel.issues == [.ruleWithoutInterval])

        viewModel.rules[0].monthInterval = NumberInput.text(Decimal(6), style: .months)
        #expect(viewModel.issues.isEmpty)
    }

    @Test("saving a new vehicle stores it with its reminders")
    func savesNewVehicle() async throws {
        let vehicles = InMemoryVehicleRepository()
        let services = InMemoryServiceRepository()
        let viewModel = makeViewModel(vehicleRepository: vehicles, serviceRepository: services)
        viewModel.name = "  Gol  "
        viewModel.kind = .motorcycle
        viewModel.plate = " abc1d23 "
        viewModel.initialOdometer = NumberInput.text(56_000.0, style: .kilometers)
        viewModel.tankCapacity = NumberInput.text(50.0, style: .liters)
        viewModel.addRule()
        viewModel.rules[0].kilometerInterval = NumberInput.text(10_000.0, style: .kilometers)

        await viewModel.save()

        let saved = try #require(try await vehicles.all(includingArchived: true).first)
        #expect(viewModel.state == .saved)
        #expect(saved.name == "Gol")
        #expect(saved.kind == .motorcycle)
        #expect(saved.plate == "ABC1D23")
        #expect(saved.initialOdometer == 56_000)
        #expect(saved.tankCapacity == 50)
        #expect(saved.createdAt == day(30))

        let rules = try await services.rules(vehicleID: saved.id)
        #expect(rules.count == 1)
        #expect(rules.first?.kilometerInterval == 10_000)
        #expect(rules.first?.monthInterval == nil)
    }

    @Test("editing pre-fills the vehicle and its reminders, sorted by kind")
    func editsExistingVehicle() async throws {
        let vehicle = Vehicle(
            name: "Jetta",
            plate: "XYZ9A87",
            initialOdometer: 144_000,
            tankCapacity: 55,
            createdAt: day(0),
            isArchived: true
        )
        let rules = [
            ServiceRule(vehicleID: vehicle.id, kind: .tires, monthInterval: 12),
            ServiceRule(vehicleID: vehicle.id, kind: .brakes, kilometerInterval: 20_000)
        ]
        let vehicles = InMemoryVehicleRepository(vehicles: [vehicle])
        let viewModel = makeViewModel(mode: .edit(vehicle), existingRules: rules, vehicleRepository: vehicles)

        #expect(viewModel.name == "Jetta")
        #expect(viewModel.plate == "XYZ9A87")
        #expect(viewModel.parsedInitialOdometer == 144_000)
        #expect(viewModel.parsedTankCapacity == 55)
        #expect(viewModel.rules.map(\.kind) == [.brakes, .tires])
        #expect(viewModel.rules[1].parsedMonthInterval == 12)

        viewModel.plate = ""
        await viewModel.save()

        let saved = try #require(try await vehicles.vehicle(id: vehicle.id))
        #expect(saved.plate == nil)
        #expect(saved.createdAt == day(0))
        #expect(saved.isArchived)
    }

    @Test("removing reminders ignores indices out of range")
    func removesRules() {
        let viewModel = makeViewModel()
        viewModel.addRule()
        viewModel.addRule()
        let kept = viewModel.rules[1].id

        viewModel.removeRules(at: IndexSet([0, 5]))

        #expect(viewModel.rules.map(\.id) == [kept])
    }

    @Test("a blocking issue prevents saving")
    func blockedSaveDoesNothing() async throws {
        let vehicles = InMemoryVehicleRepository()
        let viewModel = makeViewModel(vehicleRepository: vehicles)

        await viewModel.save()

        #expect(viewModel.state == .editing)
        #expect(try await vehicles.all(includingArchived: true).isEmpty)
    }

    @Test("a repository failure is shown to the user")
    func surfacesFailure() async {
        let viewModel = makeViewModel(
            vehicleRepository: InMemoryVehicleRepository(failure: RepositoryError.vehicleNotFound(UUID()))
        )
        viewModel.name = "Gol"

        await viewModel.save()

        guard case .failed = viewModel.state else {
            Issue.record("expected .failed, got \(viewModel.state)")
            return
        }
    }
}
