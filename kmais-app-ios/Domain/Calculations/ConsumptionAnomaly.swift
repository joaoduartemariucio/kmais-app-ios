import Foundation

nonisolated struct ConsumptionAnomaly: Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case odometerWentBackwards(previous: Double)
        case odometerUnchanged(previous: Double)
        case nonPositiveLiters
        case duplicate(of: UUID)
    }

    let record: FuelEntry
    let kind: Kind
}
