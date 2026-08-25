import Foundation
import SwiftData

@ModelActor
actor SwiftDataVehicleRepository: VehicleRepository, SwiftDataRepository {

    func all(includingArchived: Bool) async throws -> [Vehicle] {
        var descriptor = FetchDescriptor<VehicleModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if !includingArchived {
            descriptor.predicate = #Predicate { !$0.isArchived }
        }

        do {
            return try modelContext.fetch(descriptor).map(VehicleMapper.entity)
        } catch {
            throw RepositoryError.persistenceFailed(underlying: error)
        }
    }

    func vehicle(id: UUID) async throws -> Vehicle? {
        try model(id: id).map(VehicleMapper.entity)
    }

    func save(_ vehicle: Vehicle) async throws {
        let model: VehicleModel
        if let existing = try self.model(id: vehicle.id) {
            model = existing
        } else {
            model = VehicleModel(id: vehicle.id, createdAt: vehicle.createdAt)
            modelContext.insert(model)
        }

        VehicleMapper.apply(vehicle, to: model)
        try commit()
    }

    func setArchived(_ isArchived: Bool, vehicleID: UUID) async throws {
        guard let model = try model(id: vehicleID) else {
            throw RepositoryError.vehicleNotFound(vehicleID)
        }
        model.isArchived = isArchived
        try commit()
    }

    private func model(id: UUID) throws -> VehicleModel? {
        try fetchByID(id, in: modelContext, matching: #Predicate<VehicleModel> { $0.id == id })
    }
}
