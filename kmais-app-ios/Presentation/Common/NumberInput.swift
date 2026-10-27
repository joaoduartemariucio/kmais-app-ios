import Foundation

nonisolated enum NumberInput {
    enum Style: Hashable, Sendable {
        case integer
        case decimal(fractionDigits: Int)
        case currency(fractionDigits: Int)

        static let kilometers = Style.integer
        static let months = Style.integer
        static let liters = Style.decimal(fractionDigits: 2)
        static let fuelPrice = Style.currency(fractionDigits: 3)
        static let money = Style.currency(fractionDigits: 2)

        var fractionDigits: Int {
            switch self {
            case .integer: 0
            case .decimal(let digits), .currency(let digits): digits
            }
        }
    }

    private static let maxDigits = 12

    static func masked(_ text: String, previous: String, style: Style) -> String {
        var digits = digits(in: text)
        if decimal(text, style: style).map({ Self.text($0, style: style) }) == text {
            return text
        }
        if text.count < previous.count, digits == Self.digits(in: previous) {
            digits = String(digits.dropLast())
        }
        guard let value = value(fromDigits: String(digits.prefix(maxDigits)), style: style) else { return "" }
        return Self.text(value, style: style)
    }

    static func decimal(_ text: String, style: Style) -> Decimal? {
        value(fromDigits: digits(in: text), style: style)
    }

    static func double(_ text: String, style: Style) -> Double? {
        decimal(text, style: style).map { NSDecimalNumber(decimal: $0).doubleValue }
    }

    static func text(_ value: Double?, style: Style) -> String {
        text(value.map(Decimal.init(approximating:)), style: style)
    }

    static func text(_ value: Decimal?, style: Style) -> String {
        guard let value else { return "" }
        let precision = NumberFormatStyleConfiguration.Precision.fractionLength(style.fractionDigits)

        switch style {
        case .integer, .decimal:
            return value.formatted(.number.precision(precision))
        case .currency:
            return value.formatted(
                .currency(code: Locale.current.currency?.identifier ?? "BRL").precision(precision)
            )
        }
    }

    private static func digits(in text: String) -> String {
        String(text.filter { $0.isASCII && $0.isNumber })
    }

    private static func value(fromDigits digits: String, style: Style) -> Decimal? {
        guard !digits.isEmpty, let whole = Decimal(string: digits) else { return nil }
        return whole / pow(10, style.fractionDigits)
    }
}
