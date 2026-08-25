import Foundation

/// Conversão entre `VehicleModel` e a entidade `Vehicle`.
///
/// A tradução é sempre chamada de dentro do ator do repositório: é ela que
/// garante que nenhum `@Model` cruze a fronteira do domínio.
enum VehicleMapper {
    static func entity(_ model: VehicleModel) -> Vehicle {
        Vehicle(
            id: model.id,
            name: model.name,
            kind: model.kind,
            plate: model.plate,
            initialOdometer: model.initialOdometer,
            tankCapacity: model.tankCapacity,
            createdAt: model.createdAt,
            isArchived: model.isArchived
        )
    }

    /// Aplica a entidade sobre um modelo já existente ou recém-inserido.
    /// `id` e `createdAt` não são reescritos: são a identidade do registro.
    static func apply(_ entity: Vehicle, to model: VehicleModel) {
        model.name = entity.name
        model.kind = entity.kind
        model.plate = entity.plate
        model.initialOdometer = entity.initialOdometer
        model.tankCapacity = entity.tankCapacity
        model.isArchived = entity.isArchived
    }
}
