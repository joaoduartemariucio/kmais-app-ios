import Foundation

@MainActor
@Observable
final class ServiceEntryFormViewModel {
    enum Mode {
        case create(vehicleID: UUID)
        case edit(ServiceEntry)
    }

    var kind: ServiceKind
    var date: Date
    var odometer: String
    var cost: String
    var notes: String

    private(set) var state: FormState = .editing

    private let mode: Mode
    private let repository: ServiceRepository
    private let otherReadings: [OdometerSample]

    init(
        mode: Mode,
        repository: ServiceRepository,
        dateProvider: DateProvider,
        otherReadings: [OdometerSample]
    ) {
        self.mode = mode
        self.repository = repository
        self.otherReadings = otherReadings

        switch mode {
        case .create:
            kind = .oilChange
            date = dateProvider.now
            odometer = ""
            cost = ""
            notes = ""
        case let .edit(entry):
            kind = entry.kind
            date = entry.date
            odometer = NumberInput.text(entry.odometer, style: .kilometers)
            cost = NumberInput.text(entry.cost, style: .money)
            notes = entry.notes
        }
    }

    var parsedOdometer: Double? { NumberInput.double(odometer, style: .kilometers) }

    var parsedCost: Decimal { NumberInput.decimal(cost, style: .money) ?? 0 }

    var issues: [ValidationIssue] {
        var issues: [ValidationIssue] = []

        issues += ValidationIssue.odometer(parsedOdometer, at: date, otherReadings: otherReadings)

        if parsedCost < 0 { issues.append(.costNegative) }

        return issues
    }

    var canSave: Bool { !issues.blocksSaving && !state.isSaving }

    func save() async {
        guard let parsedOdometer, !issues.blocksSaving else { return }

        state = .saving
        do {
            try await repository.save(entry(odometer: parsedOdometer))
            state = .saved
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    private func entry(odometer: Double) -> ServiceEntry {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        switch mode {
        case let .create(vehicleID):
            return ServiceEntry(
                vehicleID: vehicleID,
                kind: kind,
                date: date,
                odometer: odometer,
                cost: parsedCost,
                notes: trimmedNotes
            )
        case let .edit(existing):
            return ServiceEntry(
                id: existing.id,
                vehicleID: existing.vehicleID,
                kind: kind,
                date: date,
                odometer: odometer,
                cost: parsedCost,
                notes: trimmedNotes
            )
        }
    }
}
