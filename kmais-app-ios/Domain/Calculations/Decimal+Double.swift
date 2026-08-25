import Foundation

extension Decimal {
    /// Converte um `Double` pela sua representação decimal mais curta.
    ///
    /// `Decimal(_: Double)` passa pelo valor binário exato, o que reintroduz
    /// justamente o ruído que `Decimal` existe para evitar
    /// (`Decimal(0.1)` != `0.1`). `String(value)` já produz a representação
    /// curta que arredonda de volta ao mesmo `Double`.
    init(approximating value: Double) {
        guard value.isFinite, let decimal = Decimal(string: String(value)) else {
            self = .zero
            return
        }
        self = decimal
    }
}
