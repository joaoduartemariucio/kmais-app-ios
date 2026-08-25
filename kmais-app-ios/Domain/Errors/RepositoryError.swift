import Foundation

enum RepositoryError: Error {
    case vehicleNotFound(UUID)
    case entryNotFound(UUID)
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
