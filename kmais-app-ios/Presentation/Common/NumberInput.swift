import Foundation

enum NumberInput {
    static func double(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        if let parsed = try? FloatingPointFormatStyle<Double>(locale: .current)
            .parseStrategy
            .parse(trimmed) {
            return parsed
        }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }

    static func decimal(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        if let parsed = try? Decimal.FormatStyle(locale: .current)
            .parseStrategy
            .parse(trimmed) {
            return parsed
        }
        return Decimal(string: trimmed.replacingOccurrences(of: ",", with: "."))
    }

    static func text(_ value: Double?) -> String {
        guard let value else { return "" }
        return value.formatted(.number.grouping(.never))
    }

    static func text(_ value: Decimal?) -> String {
        guard let value else { return "" }
        return value.formatted(.number.grouping(.never))
    }
}
