import Foundation
import SwiftData

protocol SwiftDataRepository: Actor {
    var modelContext: ModelContext { get }
}

extension SwiftDataRepository {
    func commit() throws {
        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.persistenceFailed(underlying: error)
        }
    }

    func fetchByID<Model: PersistentModel>(
        _ id: UUID,
        in context: ModelContext,
        matching predicate: Predicate<Model>
    ) throws -> Model? {
        var descriptor = FetchDescriptor<Model>(predicate: predicate)
        descriptor.fetchLimit = 2

        let matches: [Model]
        do {
            matches = try context.fetch(descriptor)
        } catch {
            throw RepositoryError.persistenceFailed(underlying: error)
        }

        if matches.count > 1 {
            assertionFailure("Mais de um \(Model.self) com id \(id)")
        }
        return matches.first
    }
}
