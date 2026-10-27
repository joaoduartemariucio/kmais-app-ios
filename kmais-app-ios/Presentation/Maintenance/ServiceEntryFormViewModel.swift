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
    private let lastOdometer: Double?

    init(
        mode: Mode,
        repository: ServiceRepository,
        dateProvider: DateProvider,
        lastOdometer: Double?
    ) {
        self.mode = mode
        self.repository = repository
        self.lastOdometer = lastOdometer

        switch mode {
        case .create:
            kind = .oilChange
            date = dateProvider.now
            odometer = ""
            cost = ""
            notes = ""
        case .edit(let entry):
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

        if let parsedOdometer {
            if let lastOdometer, parsedOdometer <= lastOdometer {
                issues.append(.odometerNotAfterLast(last: lastOdometer))
            }
        } else {
            issues.append(.odometerRequired)
        }

        if parsedCost < 0 { issues.append(.costNegative) }

        return issues
    }

    var canSave: Bool { issues.isEmpty && !state.isSaving }

    func save() async {
        guard let parsedOdometer, issues.isEmpty else { return }

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
        case .create(let vehicleID):
            return ServiceEntry(
                vehicleID: vehicleID,
                kind: kind,
                date: date,
                odometer: odometer,
                cost: parsedCost,
                notes: trimmedNotes
            )
        case .edit(let existing):
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
