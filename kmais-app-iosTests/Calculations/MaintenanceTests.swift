import Foundation
import Testing
@testable import kmais_app_ios

@Suite("Previsão de revisão")
struct MaintenanceTests {

    // Ritmo de referência dos cenários: 5.000 km em 100 dias = 50 km/dia.
    static let history = [sample(0, 10_000), sample(100, 15_000)]
    static let lastServiceOdometer = 10_000.0
    static let kilometersPerMonth = 50 * 365.25 / 12

    // MARK: Média de uso

    struct AverageScenario: Sendable, CustomTestStringConvertible {
        let name: String
        let samples: [OdometerSample]
        let expected: Double?

        var testDescription: String { name }
    }

    static let averageScenarios: [AverageScenario] = [
        AverageScenario(name: "histórico vazio", samples: [], expected: nil),
        AverageScenario(name: "uma amostra só", samples: [sample(0, 10_000)], expected: nil),
        AverageScenario(
            name: "duas amostras no mesmo instante",
            samples: [sample(0, 10_000), sample(0, 10_500)],
            expected: nil
        ),
        AverageScenario(
            name: "veículo parado",
            samples: [sample(0, 10_000), sample(100, 10_000)],
            expected: nil
        ),
        AverageScenario(name: "50 km por dia", samples: history, expected: kilometersPerMonth),
        AverageScenario(
            name: "amostras fora de ordem são ordenadas antes",
            samples: [sample(100, 15_000), sample(0, 10_000)],
            expected: kilometersPerMonth
        )
    ]

    @Test("averageKilometersPerMonth(_:) por cenário", arguments: averageScenarios)
    func average(_ scenario: AverageScenario) {
        let average = Maintenance.averageKilometersPerMonth(scenario.samples)

        switch (average, scenario.expected) {
        case let (actual?, expected?):
            #expect(abs(actual - expected) < 1e-9)
        case (nil, nil):
            break
        default:
            Issue.record("média \(String(describing: average)) != \(String(describing: scenario.expected))")
        }
    }

    // MARK: Previsão

    private func makeForecast(
        kilometers: Double?,
        months: Int?,
        history: [OdometerSample] = MaintenanceTests.history
    ) -> MaintenanceForecast? {
        Maintenance.forecast(
            rule: rule(kilometers: kilometers, months: months),
            lastServiceDate: day(0),
            lastServiceOdometer: Self.lastServiceOdometer,
            history: history,
            calendar: utc
        )
    }

    @Test("regra sem nenhum intervalo não prevê nada")
    func emptyRule() {
        #expect(makeForecast(kilometers: nil, months: nil) == nil)
        #expect(makeForecast(kilometers: 0, months: 0) == nil)
    }

    @Test("regra só por km sem histórico utilizável não prevê data")
    func kilometersWithoutHistory() {
        #expect(makeForecast(kilometers: 10_000, months: nil, history: []) == nil)
        #expect(makeForecast(kilometers: 10_000, months: nil, history: [sample(0, 10_000)]) == nil)
        #expect(
            makeForecast(
                kilometers: 10_000,
                months: nil,
                history: [sample(0, 10_000), sample(100, 10_000)]
            ) == nil
        )
    }

    @Test("vence por km antes do calendário")
    func distanceWinsFirst() throws {
        // Vence em 20.000 km; faltam 5.000 a 50 km/dia = 100 dias após o dia 100.
        let forecast = try #require(makeForecast(kilometers: 10_000, months: 12))

        #expect(forecast.trigger == .distance)
        #expect(forecast.dueDate == day(200))
        #expect(forecast.dueOdometer == 20_000)
        #expect(abs(try #require(forecast.averageKilometersPerMonth) - Self.kilometersPerMonth) < 1e-9)
    }

    @Test("vence por meses antes da quilometragem")
    func calendarWinsFirst() throws {
        // 6 meses a partir de 2001-01-01 = 2001-07-01, o dia 181.
        let forecast = try #require(makeForecast(kilometers: 30_000, months: 6))

        #expect(forecast.trigger == .calendar)
        #expect(forecast.dueDate == day(181))
        // O odômetro-alvo continua exposto mesmo quando não é ele que vence.
        #expect(forecast.dueOdometer == 40_000)
    }

    @Test("regra só por tempo não tem odômetro de vencimento")
    func calendarOnly() throws {
        let forecast = try #require(makeForecast(kilometers: nil, months: 6))

        #expect(forecast.trigger == .calendar)
        #expect(forecast.dueDate == day(181))
        #expect(forecast.dueOdometer == nil)
    }

    @Test("regra só por km projeta a data pelo ritmo de uso")
    func distanceOnly() throws {
        let forecast = try #require(makeForecast(kilometers: 10_000, months: nil))

        #expect(forecast.trigger == .distance)
        #expect(forecast.dueDate == day(200))
    }

    @Test("empate entre km e calendário resolve para km")
    func tieBreaksToDistance() throws {
        // 18.250 km a partir de 10.000 = alvo 28.250; faltam 13.250 a 50 km/dia
        // = 265 dias após o dia 100, ou seja o dia 365 — o mesmo de 12 meses.
        let forecast = try #require(makeForecast(kilometers: 18_250, months: 12))

        #expect(forecast.dueDate == day(365))
        #expect(forecast.trigger == .distance)
    }

    @Test("revisão já vencida devolve data no passado")
    func alreadyOverdue() throws {
        // Alvo 11.000 km já foi passado; o odômetro atual é 15.000 no dia 100.
        let forecast = try #require(makeForecast(kilometers: 1_000, months: 12))

        #expect(forecast.trigger == .distance)
        #expect(forecast.dueDate == day(20))
        #expect(forecast.dueDate < day(100))
    }

    @Test("veículo parado cai para a regra de tempo")
    func stationaryFallsBackToCalendar() throws {
        let forecast = try #require(
            makeForecast(
                kilometers: 10_000,
                months: 6,
                history: [sample(0, 10_000), sample(100, 10_000)]
            )
        )

        #expect(forecast.trigger == .calendar)
        #expect(forecast.dueDate == day(181))
        #expect(forecast.dueOdometer == 20_000)
        #expect(forecast.averageKilometersPerMonth == nil)
    }
}
