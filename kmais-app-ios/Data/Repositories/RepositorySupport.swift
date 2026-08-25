import Foundation
import SwiftData

/// Peças comuns às implementações sobre SwiftData.
///
/// Cada repositório é um `@ModelActor` com seu **próprio** `ModelContext`. A
/// consequência prática: toda escrita precisa efetivar `save()` antes de
/// retornar, senão um repositório não enxerga o que o outro acabou de gravar.
/// É por isso que `commit()` existe e é chamado em todo caminho de escrita.
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

    /// Busca por identidade de domínio.
    ///
    /// O `id` não tem constraint de unicidade — o formato CloudKit proíbe
    /// `@Attribute(.unique)`. Como o `UUID` é gerado localmente, colisão é
    /// irrelevante na prática; se acontecer, é bug nosso, então falha alto em
    /// debug e segue com o primeiro em produção.
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
