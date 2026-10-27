import Foundation
import SwiftData

@Model
final class ServiceRuleModel {
    var id: UUID = UUID()
    var kind: ServiceKind = ServiceKind.other
    var kilometerInterval: Double?
    var monthInterval: Int?
    var vehicle: VehicleModel?

    init(
        id: UUID = UUID(),
        kind: ServiceKind = .other,
        kilometerInterval: Double? = nil,
        monthInterval: Int? = nil,
        vehicle: VehicleModel? = nil
    ) {
        self.id = id
        self.kind = kind
        self.kilometerInterval = kilometerInterval
        self.monthInterval = monthInterval
        self.vehicle = vehicle
    }
}
