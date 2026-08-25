import Foundation

extension Double {
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

    var formattedConsumption: String {
        String(
            localized: "\(formatted(.number.precision(.fractionLength(1)))) km/L",
            comment: "Fuel efficiency, e.g. 12.4 km/L"
        )
    }
}

extension Decimal {
    var formattedCurrency: String {
        formatted(.currency(code: Locale.current.currency?.identifier ?? "BRL"))
    }
}

extension Date {
    var formattedDay: String { formatted(.dateTime.day().month(.abbreviated)) }
    var formattedFullDate: String { formatted(.dateTime.day().month(.wide).year()) }
    var formattedMonthAndYear: String { formatted(.dateTime.month(.wide).year()) }
}
