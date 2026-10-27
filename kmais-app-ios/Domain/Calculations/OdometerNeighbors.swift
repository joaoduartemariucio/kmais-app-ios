import Foundation

nonisolated struct OdometerNeighbors: Hashable, Sendable {
    let previous: Double?
    let next: Double?
}
