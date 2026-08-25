import Foundation

/// Acesso aos abastecimentos de um veículo.
protocol FuelEntryRepository: Sendable {
    /// Em ordem cronológica crescente.
    func entries(vehicleID: UUID) async throws -> [FuelEntry]
    /// Insere ou atualiza. O vínculo com o veículo vem do próprio
    /// `entry.vehicleID`.
    func save(_ entry: FuelEntry) async throws
    func delete(id: UUID) async throws
}
