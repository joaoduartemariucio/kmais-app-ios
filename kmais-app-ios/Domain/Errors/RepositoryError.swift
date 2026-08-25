import Foundation

/// Falhas que a camada de dados pode devolver ao domínio.
enum RepositoryError: Error {
    case vehicleNotFound(UUID)
    case entryNotFound(UUID)
    /// Falha do store por baixo. Guarda o erro original em vez de achatar em
    /// string, para que o diagnóstico não se perca.
    case persistenceFailed(underlying: Error)
}

extension RepositoryError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .vehicleNotFound:
            String(localized: "This vehicle no longer exists.")
        case .entryNotFound:
            String(localized: "This record no longer exists.")
        case .persistenceFailed:
            String(localized: "Could not save your changes.")
        }
    }
}
