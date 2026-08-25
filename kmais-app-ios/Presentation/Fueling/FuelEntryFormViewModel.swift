import Foundation

/// Formulário de abastecimento.
///
/// Os números ficam como texto: cancelar não pode tocar no banco, e "campo
/// vazio" precisa ser distinguível de "campo com zero" para a validação dizer
/// *qual* dos dois é o problema.
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

    private let mode: Mode
    private let repository: FuelEntryRepository
    /// Última leitura do veículo desconsiderando o registro em edição — senão
    /// editar o registro mais recente sempre falharia contra ele mesmo.
    ///
    /// Vem de fora porque a tela ainda não existe: quando existir, decidimos se
    /// o valor vem do detalhe já carregado ou de uma consulta própria.
    private let lastOdometer: Double?

    init(
        mode: Mode,
        repository: FuelEntryRepository,
        dateProvider: DateProvider,
        lastOdometer: Double?
    ) {
        self.mode = mode
        self.repository = repository
        self.lastOdometer = lastOdometer

        switch mode {
        case .create:
            date = dateProvider.now
            odometer = ""
            liters = ""
            pricePerLiter = ""
            isFullTank = true
        case .edit(let entry):
            date = entry.date
            odometer = NumberInput.text(entry.odometer)
            liters = NumberInput.text(entry.liters)
            pricePerLiter = NumberInput.text(entry.pricePerLiter)
            isFullTank = entry.isFullTank
        }
    }

    var parsedOdometer: Double? { NumberInput.double(odometer) }
    var parsedLiters: Double? { NumberInput.double(liters) }
    var parsedPrice: Decimal? { NumberInput.decimal(pricePerLiter) }

    /// Total do abastecimento, ao vivo enquanto o usuário digita.
    ///
    /// Sai de `FuelEntry.totalCost` e não de uma multiplicação aqui: é a mesma
    /// conta que alimenta o custo por km, e as duas não podem divergir.
    var totalCost: Decimal? {
        guard let parsedLiters, let parsedPrice else { return nil }
        return entry(odometer: parsedOdometer ?? 0, liters: parsedLiters, price: parsedPrice).totalCost
    }

    var issues: [ValidationIssue] {
        var issues: [ValidationIssue] = []

        if let parsedOdometer {
            if let lastOdometer, parsedOdometer <= lastOdometer {
                issues.append(.odometerNotAfterLast(last: lastOdometer))
            }
        } else {
            issues.append(.odometerRequired)
        }

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

    var canSave: Bool { issues.isEmpty && !state.isSaving }

    func save() async {
        guard let parsedOdometer, let parsedLiters, let parsedPrice, issues.isEmpty else { return }

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
        case .create(let vehicleID):
            FuelEntry(
                vehicleID: vehicleID,
                date: date,
                odometer: odometer,
                liters: liters,
                pricePerLiter: price,
                isFullTank: isFullTank
            )
        case .edit(let existing):
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
