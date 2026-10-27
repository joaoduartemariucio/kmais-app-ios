import Foundation
import Testing
@testable import kmais_app_ios

@MainActor
@Suite("Service entry form")
struct ServiceEntryFormViewModelTests {
    private func makeViewModel(
        mode: ServiceEntryFormViewModel.Mode = .create(vehicleID: testVehicleID),
        repository: InMemoryServiceRepository = InMemoryServiceRepository(),
        otherReadings: [OdometerSample] = []
    ) -> ServiceEntryFormViewModel {
        ServiceEntryFormViewModel(
            mode: mode,
            repository: repository,
            dateProvider: FixedDateProvider(now: day(30)),
            otherReadings: otherReadings
        )
    }

    @Test("a new form defaults to an oil change today and only needs the odometer")
    func blankForm() {
        let viewModel = makeViewModel()

        #expect(viewModel.kind == .oilChange)
        #expect(viewModel.date == day(30))
        #expect(viewModel.issues == [.odometerRequired])
        #expect(!viewModel.canSave)
    }

    @Test("an empty cost is saved as zero and notes are trimmed")
    func savesNewEntry() async throws {
        let repository = InMemoryServiceRepository()
        let viewModel = makeViewModel(repository: repository)
        viewModel.kind = .tires
        viewModel.odometer = NumberInput.text(1_500.0, style: .kilometers)
        viewModel.notes = "  front tires  \n"

        #expect(viewModel.canSave)
        await viewModel.save()

        let saved = try await repository.entries(vehicleID: testVehicleID)
        #expect(viewModel.state == .saved)
        #expect(saved.count == 1)
        #expect(saved.first?.kind == .tires)
        #expect(saved.first?.odometer == 1_500)
        #expect(saved.first?.cost == 0)
        #expect(saved.first?.notes == "front tires")
    }

    @Test("editing pre-fills the fields and keeps the entry's identity")
    func editsExistingEntry() async throws {
        let existing = ServiceEntry(
            vehicleID: testVehicleID,
            kind: .brakes,
            date: day(10),
            odometer: 1_200,
            cost: 350,
            notes: "pads"
        )
        let repository = InMemoryServiceRepository(entries: [existing])
        let viewModel = makeViewModel(mode: .edit(existing), repository: repository)

        #expect(viewModel.kind == .brakes)
        #expect(viewModel.parsedOdometer == 1_200)
        #expect(viewModel.parsedCost == 350)
        #expect(viewModel.notes == "pads")

        viewModel.cost = NumberInput.text(Decimal(400), style: .money)
        await viewModel.save()

        let saved = try await repository.entries(vehicleID: testVehicleID)
        #expect(saved.map(\.id) == [existing.id])
        #expect(saved.first?.cost == 400)
    }

    @Test("an odometer below the previous record warns but still saves")
    func outOfOrderOdometerWarns() async {
        let viewModel = makeViewModel(otherReadings: [sample(10, 2_000)])
        viewModel.odometer = NumberInput.text(1_900.0, style: .kilometers)

        #expect(viewModel.issues == [.odometerNotAfterPrevious(previous: 2_000)])

        await viewModel.save()
        #expect(viewModel.state == .saved)
    }

    @Test("a repository failure is shown to the user")
    func surfacesFailure() async {
        let viewModel = makeViewModel(
            repository: InMemoryServiceRepository(failure: RepositoryError.vehicleNotFound(testVehicleID))
        )
        viewModel.odometer = NumberInput.text(1_500.0, style: .kilometers)

        await viewModel.save()

        guard case .failed = viewModel.state else {
            Issue.record("expected .failed, got \(viewModel.state)")
            return
        }
    }

    @Test("the form shows the reading right before its date")
    func previousReading() {
        #expect(makeViewModel().previousReading == nil)
        #expect(makeViewModel(otherReadings: [sample(10, 1_000), sample(60, 2_000)]).previousReading == 1_000)
    }
}
