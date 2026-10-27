import Foundation

nonisolated protocol FuelEntryRepository: Sendable {
    func entries(vehicleID: UUID) async throws -> [FuelEntry]
    func save(_ entry: FuelEntry) async throws
    func delete(id: UUID) async throws
}
