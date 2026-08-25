import Foundation

/// Com que frequência um tipo de serviço deve se repetir. Vence o que chegar
/// primeiro entre quilometragem e tempo.
///
/// Os dois intervalos são opcionais: uma regra pode ser só por quilometragem
/// (rodízio de pneus), só por tempo (fluido de freio) ou ambos.
struct ServiceRule: Identifiable, Hashable, Sendable {
    let id: UUID
    let vehicleID: UUID
    var kind: ServiceKind
    var kilometerInterval: Double?
    var monthInterval: Int?

    init(
        id: UUID = UUID(),
        vehicleID: UUID,
        kind: ServiceKind = .other,
        kilometerInterval: Double? = nil,
        monthInterval: Int? = nil
    ) {
        self.id = id
        self.vehicleID = vehicleID
        self.kind = kind
        self.kilometerInterval = kilometerInterval
        self.monthInterval = monthInterval
    }
}
