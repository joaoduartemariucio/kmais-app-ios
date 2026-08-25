import Foundation

protocol Chronological {
    var date: Date { get }
    var odometer: Double { get }
}

extension Array where Element: Chronological {
    func sortedChronologically() -> [Element] {
        sorted { lhs, rhs in
            lhs.date == rhs.date ? lhs.odometer < rhs.odometer : lhs.date < rhs.date
        }
    }
}
