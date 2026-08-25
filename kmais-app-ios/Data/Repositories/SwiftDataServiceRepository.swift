import Foundation
import SwiftData

@ModelActor
actor SwiftDataServiceRepository: ServiceRepository, SwiftDataRepository {

    func entries(vehicleID: UUID) async throws -> [ServiceEntry] {
        let descriptor = FetchDescriptor<ServiceEntryModel>(
            predicate: #Predicate { $0.vehicle?.id == vehicleID },
            sortBy: [SortDescriptor(\.date), SortDescriptor(\.odometer)]
        )

        do {
            return try modelContext.fetch(descriptor).compactMap(ServiceMapper.entity)
        } catch {
            throw RepositoryError.persistenceFailed(underlying: error)
        }
    }

    func rules(vehicleID: UUID) async throws -> [ServiceRule] {
        let descriptor = FetchDescriptor<ServiceRuleModel>(
            predicate: #Predicate { $0.vehicle?.id == vehicleID }
        )

        do {
            return try modelContext.fetch(descriptor).compactMap(ServiceMapper.entity)
        } catch {
            throw RepositoryError.persistenceFailed(underlying: error)
        }
    }

    func save(_ entry: ServiceEntry) async throws {
        let model: ServiceEntryModel
        if let existing = try entryModel(id: entry.id) {
            model = existing
        } else {
            guard let vehicle = try vehicleModel(id: entry.vehicleID) else {
                throw RepositoryError.vehicleNotFound(entry.vehicleID)
            }
            model = ServiceEntryModel(id: entry.id, vehicle: vehicle)
            modelContext.insert(model)
        }

        ServiceMapper.apply(entry, to: model)
        try commit()
    }

    /// Reconcilia por `id`: o que sumiu do conjunto é apagado, o que já existia
    /// é atualizado no lugar, o resto é inserido.
    ///
    /// Apagar tudo e reinserir daria o mesmo estado final e seria bem mais
    /// curto — e erraria feio: com CloudKit ligado, cada salvamento do
    /// formulário viraria uma rodada de deletes e inserts para sincronizar, e
    /// as regras perderiam a identidade que as liga ao histórico.
    func save(_ rules: [ServiceRule], vehicleID: UUID) async throws {
        guard let vehicle = try vehicleModel(id: vehicleID) else {
            throw RepositoryError.vehicleNotFound(vehicleID)
        }

        let existing = Dictionary(
            vehicle.rules.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let keptIDs = Set(rules.map(\.id))

        for model in vehicle.rules where !keptIDs.contains(model.id) {
            modelContext.delete(model)
        }

        for rule in rules {
            let model: ServiceRuleModel
            if let existingModel = existing[rule.id] {
                model = existingModel
            } else {
                model = ServiceRuleModel(id: rule.id, vehicle: vehicle)
                modelContext.insert(model)
            }
            ServiceMapper.apply(rule, to: model)
        }

        try commit()
    }

    func deleteEntry(id: UUID) async throws {
        guard let model = try entryModel(id: id) else {
            throw RepositoryError.entryNotFound(id)
        }
        modelContext.delete(model)
        try commit()
    }

    func deleteRule(id: UUID) async throws {
        guard let model = try ruleModel(id: id) else {
            throw RepositoryError.entryNotFound(id)
        }
        modelContext.delete(model)
        try commit()
    }

    private func entryModel(id: UUID) throws -> ServiceEntryModel? {
        try fetchByID(id, in: modelContext, matching: #Predicate<ServiceEntryModel> { $0.id == id })
    }

    private func ruleModel(id: UUID) throws -> ServiceRuleModel? {
        try fetchByID(id, in: modelContext, matching: #Predicate<ServiceRuleModel> { $0.id == id })
    }

    private func vehicleModel(id: UUID) throws -> VehicleModel? {
        try fetchByID(id, in: modelContext, matching: #Predicate<VehicleModel> { $0.id == id })
    }
}
