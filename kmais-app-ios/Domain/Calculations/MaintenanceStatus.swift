import Foundation

nonisolated struct MaintenanceStatus: Hashable, Sendable {
    enum Level: Int, Comparable, Sendable {
        case onTrack
        case dueSoon
        case overdue

        static func < (lhs: Level, rhs: Level) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    let level: Level
    let progress: Double
    let remainingKilometers: Double?
    let remainingDays: Int
}
