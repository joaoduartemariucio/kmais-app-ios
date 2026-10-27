import Foundation
import OSLog

nonisolated enum DataLog {
    static let mapping = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "br.com.joaoduartemariucio.kmais-app-ios",
        category: "mapping"
    )

    static func orphanDiscarded(type: String, id: UUID) {
        assertionFailure("\(type) \(id) has no vehicle: discarded while reading")
        mapping.error("Discarded orphan record: \(type, privacy: .public) \(id, privacy: .public)")
    }
}
