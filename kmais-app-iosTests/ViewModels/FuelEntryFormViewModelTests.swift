import Foundation
import Testing
@testable import kmais_app_ios

@MainActor
@Suite("Fuel entry form")
struct FuelEntryFormViewModelTests {
    private func makeViewModel(
        mode: FuelEntryFormViewModel.Mode = .create(vehicleID: testVehicleID),
        repository: InMemoryFuelEntryRepository = InMemoryFuelEntryRepository(),
        otherReadings: [OdometerSample] = [],
        suggestedPrice: Decimal? = nil
    ) -> FuelEntryFormViewModel {
        FuelEntryFormViewModel(
            mode: mode,
            repository: repository,
            dateProvider: FixedDateProvider(now: day(30)),
            otherReadings: otherReadings,
            suggestedPrice: suggestedPrice
        )
    }

    private func fill(
        _ viewModel: FuelEntryFormViewModel,
        odometer: Double = 1_500,
        liters: Double = 40,
        price: Decimal = 5
    ) {
        viewModel.odometer = NumberInput.text(odometer, style: .kilometers)
        viewModel.liters = NumberInput.text(liters, style: .liters)
        viewModel.pricePerLiter = NumberInput.text(price, style: .fuelPrice)
    }

    @Test("a new form starts today, full tank, with every field required")
    func blankForm() {
        let viewModel = makeViewModel()

        #expect(viewModel.date == day(30))
        #expect(viewModel.isFullTank)
        #expect(viewModel.issues == [.odometerRequired, .litersRequired, .priceRequired])
        #expect(!viewModel.canSave)
        #expect(viewModel.totalCost == nil)
    }

    @Test("zero liters and zero price are rejected")
    func nonPositiveValues() {
        let viewModel = makeViewModel()
        fill(viewModel, liters: 0, price: 0)

        #expect(viewModel.issues == [.litersNotPositive, .priceNotPositive])
        #expect(!viewModel.canSave)
    }

    @Test("the total is liters times price")
    func totalCost() {
        let viewModel = makeViewModel()
        fill(viewModel, liters: 40, price: 5)

        #expect(viewModel.totalCost == 200)
    }

    @Test("saving creates the entry for the vehicle")
    func savesNewEntry() async throws {
        let repository = InMemoryFuelEntryRepository()
        let viewModel = makeViewModel(repository: repository)
        fill(viewModel)
        viewModel.isFullTank = false

        await viewModel.save()

        let saved = try await repository.entries(vehicleID: testVehicleID)
        #expect(viewModel.state == .saved)
        #expect(saved.count == 1)
        #expect(saved.first?.odometer == 1_500)
        #expect(saved.first?.liters == 40)
        #expect(saved.first?.pricePerLiter == 5)
        #expect(saved.first?.isFullTank == false)
    }

    @Test("editing pre-fills the fields and keeps the entry's identity")
    func editsExistingEntry() async throws {
        let existing = full(10, 1_200, 35, price: 6)
        let repository = InMemoryFuelEntryRepository(entries: [existing])
        let viewModel = makeViewModel(mode: .edit(existing), repository: repository)

        #expect(viewModel.parsedOdometer == 1_200)
        #expect(viewModel.parsedLiters == 35)
        #expect(viewModel.parsedPrice == 6)
        #expect(viewModel.date == day(10))

        viewModel.liters = NumberInput.text(36.0, style: .liters)
        await viewModel.save()

        let saved = try await repository.entries(vehicleID: testVehicleID)
        #expect(saved.map(\.id) == [existing.id])
        #expect(saved.first?.liters == 36)
    }

    @Test("an odometer out of order warns but still saves")
    func outOfOrderOdometerWarns() async {
        let viewModel = makeViewModel(otherReadings: [sample(40, 2_000)])
        fill(viewModel, odometer: 2_100)

        #expect(viewModel.issues == [.odometerNotBeforeNext(next: 2_000)])
        #expect(viewModel.canSave)

        await viewModel.save()
        #expect(viewModel.state == .saved)
    }

    @Test("a blocking issue prevents saving")
    func blockedSaveDoesNothing() async throws {
        let repository = InMemoryFuelEntryRepository()
        let viewModel = makeViewModel(repository: repository)

        await viewModel.save()

        #expect(viewModel.state == .editing)
        #expect(try await repository.entries(vehicleID: testVehicleID).isEmpty)
    }

    @Test("a repository failure is shown to the user")
    func surfacesFailure() async {
        let viewModel = makeViewModel(
            repository: InMemoryFuelEntryRepository(failure: RepositoryError.vehicleNotFound(testVehicleID))
        )
        fill(viewModel)

        await viewModel.save()

        guard case .failed = viewModel.state else {
            Issue.record("expected .failed, got \(viewModel.state)")
            return
        }
    }

    @Test("a new fuel-up starts with the suggested price; an edit keeps its own")
    func suggestedPrice() {
        let created = makeViewModel(suggestedPrice: Decimal(string: "5.899")!)
        #expect(created.parsedPrice == Decimal(string: "5.899"))
        #expect(created.isUsingSuggestedPrice)
        created.pricePerLiter = NumberInput.text(Decimal(6), style: .fuelPrice)
        #expect(!created.isUsingSuggestedPrice)

        let entry = full(10, 1_000, 30, price: 6)
        let edited = makeViewModel(mode: .edit(entry), suggestedPrice: 4)
        #expect(edited.parsedPrice == 6)
        #expect(!edited.isUsingSuggestedPrice)
        #expect(!makeViewModel().isUsingSuggestedPrice)
    }

    @Test("the form shows the previous reading and the distance driven since")
    func previousReading() {
        let viewModel = makeViewModel(otherReadings: [sample(10, 1_000), sample(60, 2_000)])

        #expect(viewModel.previousReading == 1_000)
        #expect(viewModel.distanceSincePrevious == nil)

        viewModel.odometer = NumberInput.text(1_350.0, style: .kilometers)
        #expect(viewModel.distanceSincePrevious == 350)

        viewModel.odometer = NumberInput.text(900.0, style: .kilometers)
        #expect(viewModel.distanceSincePrevious == nil)
    }
}
