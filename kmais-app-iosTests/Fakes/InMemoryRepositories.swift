import Foundation
@testable import kmais_app_ios

// Implementações em memória dos protocolos de repositório, para que ViewModels
// sejam testáveis sem SwiftData, sem ModelContainer e sem I/O.
//
// São atores pelo mesmo motivo que os repositórios reais: o protocolo é
// `Sendable` e as operações são `async`.

actor InMemoryVehicleRepository: VehicleRepository {
    private var storage: [UUID: Vehicle]
    /// Quando não-nulo, toda operação falha com este erro. Serve para exercitar
    /// os caminhos de erro dos ViewModels.
    var failure: Error?

    init(vehicles: [Vehicle] = [], failure: Error? = nil) {
        storage = Dictionary(vehicles.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.failure = failure
    }

    func setFailure(_ failure: Error?) { self.failure = failure }

    func all(includingArchived: Bool) async throws -> [Vehicle] {
        if let failure { throw failure }
        return storage.values
            .filter { includingArchived || !$0.isArchived }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func vehicle(id: UUID) async throws -> Vehicle? {
        if let failure { throw failure }
        return storage[id]
    }

    func save(_ vehicle: Vehicle) async throws {
        if let failure { throw failure }
        storage[vehicle.id] = vehicle
    }

    func setArchived(_ isArchived: Bool, vehicleID: UUID) async throws {
        if let failure { throw failure }
        guard var vehicle = storage[vehicleID] else {
            throw RepositoryError.vehicleNotFound(vehicleID)
        }
        vehicle.isArchived = isArchived
        storage[vehicleID] = vehicle
    }
}

actor InMemoryFuelEntryRepository: FuelEntryRepository {
    private var storage: [UUID: FuelEntry]
    var failure: Error?

    init(entries: [FuelEntry] = [], failure: Error? = nil) {
        storage = Dictionary(entries.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.failure = failure
    }

    func setFailure(_ failure: Error?) { self.failure = failure }

    func entries(vehicleID: UUID) async throws -> [FuelEntry] {
        if let failure { throw failure }
        return storage.values
            .filter { $0.vehicleID == vehicleID }
            .sortedChronologically()
    }

    func save(_ entry: FuelEntry) async throws {
        if let failure { throw failure }
        storage[entry.id] = entry
    }

    func delete(id: UUID) async throws {
        if let failure { throw failure }
        guard storage.removeValue(forKey: id) != nil else {
            throw RepositoryError.entryNotFound(id)
        }
    }
}

actor InMemoryServiceRepository: ServiceRepository {
    private var entryStorage: [UUID: ServiceEntry]
    private var ruleStorage: [UUID: ServiceRule]
    var failure: Error?

    init(entries: [ServiceEntry] = [], rules: [ServiceRule] = [], failure: Error? = nil) {
        entryStorage = Dictionary(entries.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        ruleStorage = Dictionary(rules.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.failure = failure
    }

    func setFailure(_ failure: Error?) { self.failure = failure }

    func entries(vehicleID: UUID) async throws -> [ServiceEntry] {
        if let failure { throw failure }
        return entryStorage.values
            .filter { $0.vehicleID == vehicleID }
            .sortedChronologically()
    }

    func rules(vehicleID: UUID) async throws -> [ServiceRule] {
        if let failure { throw failure }
        return ruleStorage.values.filter { $0.vehicleID == vehicleID }
    }

    func save(_ entry: ServiceEntry) async throws {
        if let failure { throw failure }
        entryStorage[entry.id] = entry
    }

    /// Reconcilia por `id`, como a implementação real: o que sumiu do conjunto
    /// é removido, o resto é inserido ou atualizado no lugar.
    func save(_ rules: [ServiceRule], vehicleID: UUID) async throws {
        if let failure { throw failure }

        let keptIDs = Set(rules.map(\.id))
        for (id, rule) in ruleStorage where rule.vehicleID == vehicleID && !keptIDs.contains(id) {
            ruleStorage.removeValue(forKey: id)
        }
        for rule in rules {
            ruleStorage[rule.id] = rule
        }
    }

    func deleteEntry(id: UUID) async throws {
        if let failure { throw failure }
        guard entryStorage.removeValue(forKey: id) != nil else {
            throw RepositoryError.entryNotFound(id)
        }
    }

    func deleteRule(id: UUID) async throws {
        if let failure { throw failure }
        guard ruleStorage.removeValue(forKey: id) != nil else {
            throw RepositoryError.entryNotFound(id)
        }
    }
}

/// Relógio parado, para que qualquer comportamento dependente de tempo seja
/// determinístico.
struct FixedDateProvider: DateProvider {
    let now: Date
    var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()
}
