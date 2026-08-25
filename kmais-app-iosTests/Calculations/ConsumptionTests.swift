import Foundation
import Testing
@testable import kmais_app_ios

@Suite("Consumo")
struct ConsumptionTests {

    struct Scenario: Sendable, CustomTestStringConvertible {
        let name: String
        let records: [FuelEntry]
        /// Distância e litros esperados de cada trecho, em ordem.
        let intervals: [Trecho]
        let average: Double?

        struct Trecho: Sendable {
            let distance: Double
            let liters: Double
            init(_ distance: Double, _ liters: Double) {
                self.distance = distance
                self.liters = liters
            }
        }

        var testDescription: String { name }
    }

    static let scenarios: [Scenario] = [
        Scenario(
            name: "histórico vazio",
            records: [],
            intervals: [],
            average: nil
        ),
        Scenario(
            name: "um único abastecimento não abre trecho",
            records: [full(0, 1_000, 40)],
            intervals: [],
            average: nil
        ),
        Scenario(
            name: "sequência só com tanques parciais",
            records: [partial(0, 1_000, 10), partial(5, 1_200, 12), partial(10, 1_400, 11)],
            intervals: [],
            average: nil
        ),
        Scenario(
            name: "cheio para cheio",
            records: [full(0, 1_000, 40), full(10, 1_400, 40)],
            intervals: [.init(400, 40)],
            average: 10
        ),
        Scenario(
            name: "parcial antes do primeiro cheio é ignorado",
            records: [partial(0, 900, 10), full(5, 1_000, 40), full(15, 1_400, 40)],
            intervals: [.init(400, 40)],
            average: 10
        ),
        Scenario(
            name: "um parcial no meio soma litros ao trecho",
            records: [full(0, 1_000, 40), partial(5, 1_200, 20), full(10, 1_400, 20)],
            intervals: [.init(400, 40)],
            average: 10
        ),
        Scenario(
            name: "múltiplos parciais no meio do mesmo trecho",
            records: [
                full(0, 1_000, 50),
                partial(2, 1_100, 10),
                partial(4, 1_200, 10),
                partial(6, 1_300, 10),
                full(8, 1_500, 20)
            ],
            intervals: [.init(500, 50)],
            average: 10
        ),
        Scenario(
            name: "dois trechos consecutivos, média ponderada",
            records: [full(0, 1_000, 40), full(10, 1_400, 40), full(20, 1_800, 50)],
            intervals: [.init(400, 40), .init(400, 50)],
            average: 800.0 / 90.0
        ),
        Scenario(
            name: "odômetro que retrocede descarta só o trecho afetado",
            records: [full(0, 1_000, 40), full(10, 900, 40), full(20, 1_400, 50)],
            intervals: [.init(500, 50)],
            average: 10
        ),
        Scenario(
            name: "odômetro parado entre dois cheios não vira trecho",
            records: [full(0, 1_000, 40), full(10, 1_000, 30)],
            intervals: [],
            average: nil
        ),
        Scenario(
            name: "registro com litros não positivos é ignorado",
            records: [full(0, 1_000, 40), full(10, 1_400, 0)],
            intervals: [],
            average: nil
        ),
        Scenario(
            name: "array fora de ordem cronológica é ordenado antes do cálculo",
            records: [full(10, 1_400, 40), full(0, 1_000, 40)],
            intervals: [.init(400, 40)],
            average: 10
        )
    ]

    @Test("intervals(from:) e average(from:) por cenário", arguments: scenarios)
    func scenario(_ scenario: Scenario) {
        let intervals = Consumption.intervals(from: scenario.records)

        #expect(intervals.count == scenario.intervals.count)
        for (actual, expected) in zip(intervals, scenario.intervals) {
            #expect(actual.distance == expected.distance)
            #expect(actual.liters == expected.liters)
            #expect(actual.kilometersPerLiter == expected.distance / expected.liters)
        }

        let average = Consumption.average(from: scenario.records)
        switch (average, scenario.average) {
        case let (actual?, expected?):
            #expect(abs(actual - expected) < 1e-9)
        case (nil, nil):
            break
        default:
            Issue.record("média \(String(describing: average)) != \(String(describing: scenario.average))")
        }
    }

    @Test("latest(from:) devolve o trecho mais recente")
    func latest() {
        let records = [full(0, 1_000, 40), full(10, 1_400, 40), full(20, 1_800, 50)]
        let latest = Consumption.latest(from: records)

        #expect(latest?.startOdometer == 1_400)
        #expect(latest?.endOdometer == 1_800)
        #expect(latest?.liters == 50)
    }

    @Test("latest(from:) é nil sem trecho fechado")
    func latestWithoutInterval() {
        #expect(Consumption.latest(from: [full(0, 1_000, 40)]) == nil)
    }

    @Test("o trecho carrega as datas dos cheios que o delimitam")
    func intervalDates() {
        let interval = Consumption.latest(from: [full(3, 1_000, 40), full(13, 1_400, 40)])

        #expect(interval?.startDate == day(3))
        #expect(interval?.endDate == day(13))
    }
}
