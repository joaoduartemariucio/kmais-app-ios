import Foundation

struct OdometerSample: Hashable, Sendable, Chronological {
    var date: Date
    var odometer: Double
}
