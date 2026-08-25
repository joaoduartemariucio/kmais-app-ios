import Foundation

nonisolated protocol ServiceRepository: Sendable {
    func entries(vehicleID: UUID) async throws -> [ServiceEntry]
    func rules(vehicleID: UUID) async throws -> [ServiceRule]

    func save(_ entry: ServiceEntry) async throws

    func save(_ rules: [ServiceRule], vehicleID: UUID) async throws

    func deleteEntry(id: UUID) async throws
    func deleteRule(id: UUID) async throws
}
