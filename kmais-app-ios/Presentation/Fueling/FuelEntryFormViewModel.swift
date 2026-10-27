import Foundation

@MainActor
@Observable
final class FuelEntryFormViewModel {
    enum Mode {
        case create(vehicleID: UUID)
        case edit(FuelEntry)
    }

    var date: Date
    var odometer: String
    var liters: String
    var pricePerLiter: String
    var isFullTank: Bool

    private(set) var state: FormState = .editing
    private let suggestedPriceText: String?

    private let mode: Mode
    private let repository: FuelEntryRepository
    private let otherReadings: [OdometerSample]

    init(
        mode: Mode,
        repository: FuelEntryRepository,
        dateProvider: DateProvider,
        otherReadings: [OdometerSample],
        suggestedPrice: Decimal? = nil
    ) {
        self.mode = mode
        self.repository = repository
        self.otherReadings = otherReadings
        if case .create = mode, let suggestedPrice {
            suggestedPriceText = NumberInput.text(suggestedPrice, style: .fuelPrice)
        } else {
            suggestedPriceText = nil
        }

        switch mode {
        case .create:
            date = dateProvider.now
            odometer = ""
            liters = ""
            pricePerLiter = suggestedPriceText ?? ""
            isFullTank = true
        case let .edit(entry):
            date = entry.date
            odometer = NumberInput.text(entry.odometer, style: .kilometers)
            liters = NumberInput.text(entry.liters, style: .liters)
            pricePerLiter = NumberInput.text(entry.pricePerLiter, style: .fuelPrice)
            isFullTank = entry.isFullTank
        }
    }

    var parsedOdometer: Double? { NumberInput.double(odometer, style: .kilometers) }
    var parsedLiters: Double? { NumberInput.double(liters, style: .liters) }
    var parsedPrice: Decimal? { NumberInput.decimal(pricePerLiter, style: .fuelPrice) }

    var isUsingSuggestedPrice: Bool { suggestedPriceText != nil && pricePerLiter == suggestedPriceText }

    var previousReading: Double? { Odometer.neighbors(of: date, in: otherReadings).previous }

    var distanceSincePrevious: Double? {
        guard let parsedOdometer, let previousReading, parsedOdometer > previousReading else { return nil }
        return parsedOdometer - previousReading
    }

    var totalCost: Decimal? {
        guard let parsedLiters, let parsedPrice else { return nil }
        return entry(odometer: parsedOdometer ?? 0, liters: parsedLiters, price: parsedPrice).totalCost
    }

    var issues: [ValidationIssue] {
        var issues: [ValidationIssue] = []

        issues += ValidationIssue.odometer(parsedOdometer, at: date, otherReadings: otherReadings)

        if let parsedLiters {
            if parsedLiters <= 0 { issues.append(.litersNotPositive) }
        } else {
            issues.append(.litersRequired)
        }

        if let parsedPrice {
            if parsedPrice <= 0 { issues.append(.priceNotPositive) }
        } else {
            issues.append(.priceRequired)
        }

        return issues
    }

    var canSave: Bool { !issues.blocksSaving && !state.isSaving }

    func save() async {
        guard let parsedOdometer, let parsedLiters, let parsedPrice, !issues.blocksSaving else { return }

        state = .saving
        do {
            try await repository.save(
                entry(odometer: parsedOdometer, liters: parsedLiters, price: parsedPrice)
            )
            state = .saved
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    private func entry(odometer: Double, liters: Double, price: Decimal) -> FuelEntry {
        switch mode {
        case let .create(vehicleID):
            FuelEntry(
                vehicleID: vehicleID,
                date: date,
                odometer: odometer,
                liters: liters,
                pricePerLiter: price,
                isFullTank: isFullTank
            )
        case let .edit(existing):
            FuelEntry(
                id: existing.id,
                vehicleID: existing.vehicleID,
                date: date,
                odometer: odometer,
                liters: liters,
                pricePerLiter: price,
                isFullTank: isFullTank
            )
        }
    }
}
