import Foundation

nonisolated struct ServiceRule: Identifiable, Hashable, Sendable {
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
