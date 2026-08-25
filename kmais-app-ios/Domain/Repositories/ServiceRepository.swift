import Foundation

/// Acesso aos serviços executados e às regras de revisão de um veículo.
protocol ServiceRepository: Sendable {
    /// Em ordem cronológica crescente.
    func entries(vehicleID: UUID) async throws -> [ServiceEntry]
    func rules(vehicleID: UUID) async throws -> [ServiceRule]

    func save(_ entry: ServiceEntry) async throws

    /// Substitui o conjunto de regras do veículo.
    ///
    /// O formulário do veículo edita todas as regras de uma vez, então a
    /// operação é sobre o conjunto. A implementação reconcilia por `id` —
    /// apagar tudo e reinserir geraria churn de sync e perderia histórico a
    /// cada salvamento.
    func save(_ rules: [ServiceRule], vehicleID: UUID) async throws

    func deleteEntry(id: UUID) async throws
    func deleteRule(id: UUID) async throws
}
