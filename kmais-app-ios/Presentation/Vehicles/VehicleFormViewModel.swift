import Foundation

/// Formulário de veículo, incluindo as regras de revisão.
///
/// As regras são editadas junto com o veículo e salvas como conjunto: é o
/// repositório que reconcilia por `id`.
@MainActor
@Observable
final class VehicleFormViewModel {

    /// Uma regra em edição. Carrega o `id` da regra existente para que o
    /// repositório distinga atualização de inserção.
    struct RuleDraft: Identifiable, Hashable {
        let id: UUID
        var kind: ServiceKind
        var kilometerInterval: String
        var monthInterval: String

        init(kind: ServiceKind = .oilChange) {
            id = UUID()
            self.kind = kind
            kilometerInterval = ""
            monthInterval = ""
        }

        init(rule: ServiceRule) {
            id = rule.id
            kind = rule.kind
            kilometerInterval = NumberInput.text(rule.kilometerInterval)
            monthInterval = rule.monthInterval.map(String.init) ?? ""
        }

        var parsedKilometerInterval: Double? {
            guard let value = NumberInput.double(kilometerInterval), value > 0 else { return nil }
            return value
        }

        var parsedMonthInterval: Int? {
            guard let value = NumberInput.double(monthInterval), value > 0 else { return nil }
            return Int(value)
        }

        var issues: [ValidationIssue] {
            parsedKilometerInterval == nil && parsedMonthInterval == nil
                ? [.ruleWithoutInterval]
                : []
        }
    }

    enum Mode {
        case create
        case edit(Vehicle)
    }

    var name: String
    var kind: VehicleKind
    var plate: String
    var initialOdometer: String
    var tankCapacity: String
    var rules: [RuleDraft]

    private(set) var state: FormState = .editing

    private let mode: Mode
    private let vehicleRepository: VehicleRepository
    private let serviceRepository: ServiceRepository
    private let dateProvider: DateProvider

    init(
        mode: Mode,
        existingRules: [ServiceRule] = [],
        vehicleRepository: VehicleRepository,
        serviceRepository: ServiceRepository,
        dateProvider: DateProvider
    ) {
        self.mode = mode
        self.vehicleRepository = vehicleRepository
        self.serviceRepository = serviceRepository
        self.dateProvider = dateProvider

        switch mode {
        case .create:
            name = ""
            kind = .car
            plate = ""
            initialOdometer = ""
            tankCapacity = ""
        case .edit(let vehicle):
            name = vehicle.name
            kind = vehicle.kind
            plate = vehicle.plate ?? ""
            initialOdometer = NumberInput.text(vehicle.initialOdometer)
            tankCapacity = NumberInput.text(vehicle.tankCapacity)
        }

        rules = existingRules
            .sorted { $0.kind.rawValue < $1.kind.rawValue }
            .map(RuleDraft.init(rule:))
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Placa vazia vira `nil`: o domínio já modela "sem placa" como ausência, e
    /// string vazia seria um segundo jeito de dizer a mesma coisa.
    var parsedPlate: String? {
        let trimmed = plate.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed.uppercased()
    }

    var parsedInitialOdometer: Double { NumberInput.double(initialOdometer) ?? 0 }
    var parsedTankCapacity: Double? { NumberInput.double(tankCapacity) }

    var issues: [ValidationIssue] {
        var issues: [ValidationIssue] = []
        if trimmedName.isEmpty { issues.append(.nameRequired) }
        issues.append(contentsOf: rules.flatMap(\.issues))
        return issues
    }

    var canSave: Bool { issues.isEmpty && !state.isSaving }

    func addRule() {
        rules.append(RuleDraft())
    }

    func removeRules(at offsets: IndexSet) {
        // Sem `remove(atOffsets:)`: é SwiftUI, e o ViewModel não precisa
        // importar a camada de view para tirar item de um array.
        for index in offsets.sorted(by: >) where rules.indices.contains(index) {
            rules.remove(at: index)
        }
    }

    func save() async {
        guard issues.isEmpty else { return }

        state = .saving
        let vehicle = self.vehicle()
        do {
            try await vehicleRepository.save(vehicle)
            try await serviceRepository.save(
                rules.map { draft in
                    ServiceRule(
                        id: draft.id,
                        vehicleID: vehicle.id,
                        kind: draft.kind,
                        kilometerInterval: draft.parsedKilometerInterval,
                        monthInterval: draft.parsedMonthInterval
                    )
                },
                vehicleID: vehicle.id
            )
            state = .saved
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    private func vehicle() -> Vehicle {
        switch mode {
        case .create:
            Vehicle(
                name: trimmedName,
                kind: kind,
                plate: parsedPlate,
                initialOdometer: parsedInitialOdometer,
                tankCapacity: parsedTankCapacity,
                createdAt: dateProvider.now
            )
        case .edit(let existing):
            Vehicle(
                id: existing.id,
                name: trimmedName,
                kind: kind,
                plate: parsedPlate,
                initialOdometer: parsedInitialOdometer,
                tankCapacity: parsedTankCapacity,
                createdAt: existing.createdAt,
                isArchived: existing.isArchived
            )
        }
    }
}
