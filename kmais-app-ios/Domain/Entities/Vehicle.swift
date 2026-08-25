import Foundation

/// Um veículo, como o domínio o enxerga.
///
/// Struct e não `@Model`: o cálculo e os ViewModels trabalham em cima disto,
/// e a persistência é detalhe da camada `Data`.
struct Vehicle: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var kind: VehicleKind
    /// `nil` quando o veículo ainda não foi emplacado.
    var plate: String?
    var initialOdometer: Double
    /// Em litros. `nil` quando o usuário não informou.
    var tankCapacity: Double?
    var createdAt: Date
    /// Veículo vendido continua no banco: o histórico ainda conta para o custo
    /// total. Some das listas sem que apagar seja a única saída.
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        name: String,
        kind: VehicleKind = .car,
        plate: String? = nil,
        initialOdometer: Double = 0,
        tankCapacity: Double? = nil,
        createdAt: Date,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.plate = plate
        self.initialOdometer = initialOdometer
        self.tankCapacity = tankCapacity
        self.createdAt = createdAt
        self.isArchived = isArchived
    }
}
