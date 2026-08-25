import Foundation

// Formatação de tudo que a UI mostra. Nenhum símbolo de moeda nem separador
// decimal chumbado: quem decide é o locale do device.

extension Double {
    /// Distância com a unidade sempre em km.
    ///
    /// `usage: .asProvided` é essencial: com o padrão, um device em en_US
    /// converteria o odômetro para milhas.
    func formattedKilometers(fractionDigits: Int = 0) -> String {
        Measurement(value: self, unit: UnitLength.kilometers)
            .formatted(
                .measurement(
                    width: .abbreviated,
                    usage: .asProvided,
                    numberFormatStyle: .number.precision(.fractionLength(fractionDigits))
                )
            )
    }

    /// Volume sempre em litros, pelo mesmo motivo.
    func formattedLiters(fractionDigits: Int = 2) -> String {
        Measurement(value: self, unit: UnitVolume.liters)
            .formatted(
                .measurement(
                    width: .abbreviated,
                    usage: .asProvided,
                    numberFormatStyle: .number.precision(.fractionLength(fractionDigits))
                )
            )
    }

    /// Consumo. Não há unidade de km/l no Foundation, então o número é
    /// formatado pelo locale e o sufixo vem do String Catalog.
    var formattedConsumption: String {
        String(
            localized: "\(formatted(.number.precision(.fractionLength(1)))) km/L",
            comment: "Fuel efficiency, e.g. 12.4 km/L"
        )
    }
}

extension Decimal {
    /// Valor monetário na moeda do locale do device.
    var formattedCurrency: String {
        formatted(.currency(code: Locale.current.currency?.identifier ?? "BRL"))
    }
}

extension Date {
    var formattedDay: String { formatted(.dateTime.day().month(.abbreviated)) }
    var formattedFullDate: String { formatted(.dateTime.day().month(.wide).year()) }
    var formattedMonthAndYear: String { formatted(.dateTime.month(.wide).year()) }
}
