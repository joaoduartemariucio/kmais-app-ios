import Foundation

nonisolated protocol VehicleRepository: Sendable {
    func all(includingArchived: Bool) async throws -> [Vehicle]
    func vehicle(id: UUID) async throws -> Vehicle?
    func save(_ vehicle: Vehicle) async throws
    func setArchived(_ isArchived: Bool, vehicleID: UUID) async throws
}
