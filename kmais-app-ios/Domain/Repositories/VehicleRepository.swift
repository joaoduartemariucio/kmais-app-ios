import Foundation

/// Acesso ao agregado veículo.
///
/// Entra e sai entidade de domínio; `@Model` não cruza esta fronteira. Quando o
/// projeto subir para iOS 27, a observação contínua entra como um método
/// aditivo (`observeAll()`) na implementação — nada aqui precisa mudar.
protocol VehicleRepository: Sendable {
    func all(includingArchived: Bool) async throws -> [Vehicle]
    func vehicle(id: UUID) async throws -> Vehicle?
    /// Insere se não existir, atualiza se existir. O `id` da entidade é a
    /// chave.
    func save(_ vehicle: Vehicle) async throws
    func setArchived(_ isArchived: Bool, vehicleID: UUID) async throws
}
