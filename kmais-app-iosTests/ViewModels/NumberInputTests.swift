import Foundation
import Testing
@testable import kmais_app_ios

@Suite("Number input mask")
struct NumberInputTests {
    @Test("typed digits shift into the fraction digits of each style", arguments: [
        (NumberInput.Style.kilometers, "42350", Decimal(42_350)),
        (NumberInput.Style.liters, "4050", Decimal(string: "40.5")!),
        (NumberInput.Style.fuelPrice, "5899", Decimal(string: "5.899")!),
        (NumberInput.Style.money, "15000", Decimal(150))
    ])
    func shiftsDigits(style: NumberInput.Style, typed: String, expected: Decimal) {
        let masked = NumberInput.masked(typed, previous: "", style: style)

        #expect(masked == NumberInput.text(expected, style: style))
        #expect(NumberInput.decimal(masked, style: style) == expected)
    }

    @Test("an empty field stays empty and distinct from zero")
    func emptyIsNotZero() {
        #expect(NumberInput.masked("", previous: "1", style: .liters).isEmpty)
        #expect(NumberInput.decimal("", style: .liters) == nil)
        #expect(NumberInput.decimal(NumberInput.masked("0", previous: "", style: .liters), style: .liters) == 0)
    }

    @Test("formatted text is left untouched")
    func idempotent() {
        let formatted = NumberInput.text(Decimal(string: "5.899"), style: .fuelPrice)

        #expect(NumberInput.masked(formatted, previous: "", style: .fuelPrice) == formatted)
    }

    @Test("deleting a non-digit character removes the last digit instead")
    func deletingSymbolDropsDigit() {
        let formatted = NumberInput.text(Decimal(string: "40.5"), style: .liters)

        let masked = NumberInput.masked(formatted + " ", previous: formatted + " L", style: .liters)

        #expect(NumberInput.decimal(masked, style: .liters) == Decimal(string: "4.05"))
    }

    @Test("edit mode round-trips a stored value")
    func roundTrip() {
        let text = NumberInput.text(42_000.0, style: .kilometers)

        #expect(NumberInput.double(text, style: .kilometers) == 42_000)
    }
}
