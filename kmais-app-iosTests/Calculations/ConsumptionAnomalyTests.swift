import Foundation
import Testing
@testable import kmais_app_ios

@Suite("Consumption anomalies")
struct ConsumptionAnomalyTests {
    static let first = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    struct Scenario: Sendable, CustomTestStringConvertible {
        let name: String
        let records: [FuelEntry]
        let expected: [ConsumptionAnomaly.Kind]

        var testDescription: String { name }
    }

    static let scenarios: [Scenario] = [
        Scenario(name: "empty history", records: [], expected: []),
        Scenario(
            name: "a consistent history yields no anomaly",
            records: [full(0, 1_000, 40), partial(5, 1_200, 20), full(10, 1_400, 20)],
            expected: []
        ),
        Scenario(
            name: "a backwards odometer",
            records: [full(0, 1_000, 40), full(10, 900, 40)],
            expected: [.odometerWentBackwards(previous: 1_000)]
        ),
        Scenario(
            name: "one isolated mistake does not taint the records that follow",
            records: [full(0, 1_000, 40), full(10, 900, 40), full(20, 1_100, 40)],
            expected: [.odometerWentBackwards(previous: 1_000)]
        ),
        Scenario(
            name: "zero liters",
            records: [full(0, 1_000, 40), full(10, 1_400, 0)],
            expected: [.nonPositiveLiters]
        ),
        Scenario(
            name: "negative liters",
            records: [full(0, 1_000, 40), full(10, 1_400, -5)],
            expected: [.nonPositiveLiters]
        ),
        Scenario(
            name: "an unchanged odometer with different data",
            records: [full(0, 1_000, 40), full(10, 1_000, 30)],
            expected: [.odometerUnchanged(previous: 1_000)]
        ),
        Scenario(
            name: "an identical duplicate from import or sync",
            records: [full(0, 1_000, 40, id: first), full(0, 1_000, 40)],
            expected: [.duplicate(of: first)]
        ),
        Scenario(
            name: "one record can accumulate more than one anomaly",
            records: [full(0, 1_000, 40), full(10, 900, 0)],
            expected: [.nonPositiveLiters, .odometerWentBackwards(previous: 1_000)]
        )
    ]

    @Test("anomalies(in:) per scenario", arguments: scenarios)
    func scenario(_ scenario: Scenario) {
        let anomalies = Consumption.anomalies(in: scenario.records)
        #expect(anomalies.map(\.kind) == scenario.expected)
    }

    @Test("the anomaly points at the record that caused it")
    func anomalyIdentifiesRecord() {
        let bad = full(10, 900, 40, id: Self.first)
        let anomalies = Consumption.anomalies(in: [full(0, 1_000, 40), bad])

        #expect(anomalies.count == 1)
        #expect(anomalies.first?.record.id == Self.first)
    }

    @Test("anomaly detection and calculation are independent passes")
    func anomaliesDoNotAffectIntervals() {
        let records = [full(0, 1_000, 40), full(10, 900, 40), full(20, 1_400, 50)]

        #expect(Consumption.anomalies(in: records).count == 1)
        #expect(Consumption.intervals(from: records).count == 1)
    }
}
