import Foundation

nonisolated extension Decimal {
    init(approximating value: Double) {
        guard value.isFinite, let decimal = Decimal(string: String(value)) else {
            self = .zero
            return
        }
        self = decimal
    }
}
