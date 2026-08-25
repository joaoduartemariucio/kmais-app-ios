import Foundation

/// Conversão entre texto digitado e número, respeitando o locale.
///
/// Os formulários guardam texto, não número: só assim "campo vazio" e "campo
/// com zero" são estados distintos, e a validação consegue dizer *qual* dos
/// dois é o problema. A conversão passa pelo `ParseStrategy` do `FormatStyle`
/// para que vírgula e ponto sigam o locale do device em vez de uma regra
/// chumbada.
enum NumberInput {

    static func double(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        if let parsed = try? FloatingPointFormatStyle<Double>(locale: .current)
            .parseStrategy
            .parse(trimmed) {
            return parsed
        }
        // Teclado numérico de um locale, texto colado de outro: aceita a
        // notação alheia em vez de descartar o que o usuário digitou.
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

    /// Preenche o campo na edição de um registro existente.
    static func text(_ value: Double?) -> String {
        guard let value else { return "" }
        return value.formatted(.number.grouping(.never))
    }

    static func text(_ value: Decimal?) -> String {
        guard let value else { return "" }
        return value.formatted(.number.grouping(.never))
    }
}
