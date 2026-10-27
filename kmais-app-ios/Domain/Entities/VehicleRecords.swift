import Foundation

nonisolated struct VehicleRecords: Hashable, Sendable {
    let vehicle: Vehicle
    let fuel: [FuelEntry]
    let services: [ServiceEntry]
    let rules: [ServiceRule]
}
