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

    var formattedKilometersPerMonth: String {
        String(localized: "\(formattedKilometers())/month", comment: "Driving pace, e.g. 1,200 km/month")
    }

    var formattedRemainingKilometers: String {
        self > 0
            ? String(localized: "\(formattedKilometers()) left", comment: "Distance until a service is due")
            : String(
                localized: "\((-self).formattedKilometers()) past due",
                comment: "Distance driven after a service was due"
            )
    }
}

extension Int {
    var formattedRelativeDays: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .full
        return formatter.localizedString(from: DateComponents(day: self))
    }
}

extension Decimal {
    var formattedCurrency: String {
        formatted(.currency(code: Locale.current.currency?.identifier ?? "BRL"))
    }

    var formattedPerKilometer: String {
        String(localized: "\(formattedCurrency)/km", comment: "Cost per kilometer, e.g. R$ 0.85/km")
    }

    var formattedPerLiter: String {
        String(localized: "\(formattedCurrency)/L", comment: "Fuel price, e.g. R$ 5.89/L")
    }
}

extension Date {
    var formattedDay: String { formatted(.dateTime.day().month(.abbreviated)) }
    var formattedFullDate: String { formatted(.dateTime.day().month(.wide).year()) }
    var formattedMonthAndYear: String { formatted(.dateTime.month(.wide).year()) }
    var formattedShortMonth: String { formatted(.dateTime.month(.abbreviated)) }
}
