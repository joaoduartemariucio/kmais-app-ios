import Foundation
import SwiftData

@ModelActor
actor SwiftDataFuelEntryRepository: FuelEntryRepository, SwiftDataRepository {

    func entries(vehicleID: UUID) async throws -> [FuelEntry] {
        let descriptor = FetchDescriptor<FuelEntryModel>(
            predicate: #Predicate { $0.vehicle?.id == vehicleID },
            sortBy: [SortDescriptor(\.date), SortDescriptor(\.odometer)]
        )

        do {
            return try modelContext.fetch(descriptor).compactMap(FuelEntryMapper.entity)
        } catch {
            throw RepositoryError.persistenceFailed(underlying: error)
        }
    }

    func save(_ entry: FuelEntry) async throws {
        let model: FuelEntryModel
        if let existing = try self.model(id: entry.id) {
            model = existing
        } else {
            guard let vehicle = try vehicleModel(id: entry.vehicleID) else {
                throw RepositoryError.vehicleNotFound(entry.vehicleID)
            }
            model = FuelEntryModel(id: entry.id, vehicle: vehicle)
            modelContext.insert(model)
        }

        FuelEntryMapper.apply(entry, to: model)
        try commit()
    }

    func delete(id: UUID) async throws {
        guard let model = try model(id: id) else {
            throw RepositoryError.entryNotFound(id)
        }
        modelContext.delete(model)
        try commit()
    }

    private func model(id: UUID) throws -> FuelEntryModel? {
        try fetchByID(id, in: modelContext, matching: #Predicate<FuelEntryModel> { $0.id == id })
    }

    private func vehicleModel(id: UUID) throws -> VehicleModel? {
        try fetchByID(id, in: modelContext, matching: #Predicate<VehicleModel> { $0.id == id })
    }
}
