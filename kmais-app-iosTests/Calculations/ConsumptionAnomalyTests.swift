import Foundation
import Testing
@testable import kmais_app_ios

@Suite("Anomalias de consumo")
struct ConsumptionAnomalyTests {

    static let first = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    struct Scenario: Sendable, CustomTestStringConvertible {
        let name: String
        let records: [FuelEntry]
        let expected: [ConsumptionAnomaly.Kind]

        var testDescription: String { name }
    }

    static let scenarios: [Scenario] = [
        Scenario(name: "histórico vazio", records: [], expected: []),
        Scenario(
            name: "histórico consistente não gera anomalia",
            records: [full(0, 1_000, 40), partial(5, 1_200, 20), full(10, 1_400, 20)],
            expected: []
        ),
        Scenario(
            name: "odômetro que retrocede",
            records: [full(0, 1_000, 40), full(10, 900, 40)],
            expected: [.odometerWentBackwards(previous: 1_000)]
        ),
        Scenario(
            name: "um erro isolado não contamina os registros seguintes",
            records: [full(0, 1_000, 40), full(10, 900, 40), full(20, 1_100, 40)],
            expected: [.odometerWentBackwards(previous: 1_000)]
        ),
        Scenario(
            name: "litros zerados",
            records: [full(0, 1_000, 40), full(10, 1_400, 0)],
            expected: [.nonPositiveLiters]
        ),
        Scenario(
            name: "litros negativos",
            records: [full(0, 1_000, 40), full(10, 1_400, -5)],
            expected: [.nonPositiveLiters]
        ),
        Scenario(
            name: "odômetro parado com dados diferentes",
            records: [full(0, 1_000, 40), full(10, 1_000, 30)],
            expected: [.odometerUnchanged(previous: 1_000)]
        ),
        Scenario(
            name: "duplicata idêntica vinda de importação ou sync",
            records: [full(0, 1_000, 40, id: first), full(0, 1_000, 40)],
            expected: [.duplicate(of: first)]
        ),
        Scenario(
            name: "um registro pode acumular mais de uma anomalia",
            records: [full(0, 1_000, 40), full(10, 900, 0)],
            expected: [.nonPositiveLiters, .odometerWentBackwards(previous: 1_000)]
        )
    ]

    @Test("anomalies(in:) por cenário", arguments: scenarios)
    func scenario(_ scenario: Scenario) {
        let anomalies = Consumption.anomalies(in: scenario.records)
        #expect(anomalies.map(\.kind) == scenario.expected)
    }

    @Test("a anomalia aponta para o registro que a causou")
    func anomalyIdentifiesRecord() {
        let bad = full(10, 900, 40, id: Self.first)
        let anomalies = Consumption.anomalies(in: [full(0, 1_000, 40), bad])

        #expect(anomalies.count == 1)
        #expect(anomalies.first?.record.id == Self.first)
    }

    @Test("anomalia e cálculo são passadas independentes")
    func anomaliesDoNotAffectIntervals() {
        let records = [full(0, 1_000, 40), full(10, 900, 40), full(20, 1_400, 50)]

        #expect(Consumption.anomalies(in: records).count == 1)
        #expect(Consumption.intervals(from: records).count == 1)
    }
}
