import Foundation
import Testing
@testable import kmais_app_ios

@Suite("Consumption")
struct ConsumptionTests {
    struct Scenario: Sendable, CustomTestStringConvertible {
        let name: String
        let records: [FuelEntry]
        let intervals: [Leg]
        let average: Double?

        struct Leg: Sendable {
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
            name: "empty history",
            records: [],
            intervals: [],
            average: nil
        ),
        Scenario(
            name: "a single fill-up does not open a leg",
            records: [full(0, 1_000, 40)],
            intervals: [],
            average: nil
        ),
        Scenario(
            name: "a sequence of partial fills only",
            records: [partial(0, 1_000, 10), partial(5, 1_200, 12), partial(10, 1_400, 11)],
            intervals: [],
            average: nil
        ),
        Scenario(
            name: "full tank to full tank",
            records: [full(0, 1_000, 40), full(10, 1_400, 40)],
            intervals: [.init(400, 40)],
            average: 10
        ),
        Scenario(
            name: "a partial fill before the first full tank is ignored",
            records: [partial(0, 900, 10), full(5, 1_000, 40), full(15, 1_400, 40)],
            intervals: [.init(400, 40)],
            average: 10
        ),
        Scenario(
            name: "a partial fill in between adds liters to the leg",
            records: [full(0, 1_000, 40), partial(5, 1_200, 20), full(10, 1_400, 20)],
            intervals: [.init(400, 40)],
            average: 10
        ),
        Scenario(
            name: "multiple partial fills within the same leg",
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
            name: "two consecutive legs, weighted average",
            records: [full(0, 1_000, 40), full(10, 1_400, 40), full(20, 1_800, 50)],
            intervals: [.init(400, 40), .init(400, 50)],
            average: 800.0 / 90.0
        ),
        Scenario(
            name: "a backwards odometer discards only the affected leg",
            records: [full(0, 1_000, 40), full(10, 900, 40), full(20, 1_400, 50)],
            intervals: [.init(500, 50)],
            average: 10
        ),
        Scenario(
            name: "an unchanged odometer between two full tanks is not a leg",
            records: [full(0, 1_000, 40), full(10, 1_000, 30)],
            intervals: [],
            average: nil
        ),
        Scenario(
            name: "a record with non-positive liters is ignored",
            records: [full(0, 1_000, 40), full(10, 1_400, 0)],
            intervals: [],
            average: nil
        ),
        Scenario(
            name: "an out-of-order array is sorted before calculating",
            records: [full(10, 1_400, 40), full(0, 1_000, 40)],
            intervals: [.init(400, 40)],
            average: 10
        )
    ]

    @Test("intervals(from:) and average(from:) per scenario", arguments: scenarios)
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
            Issue.record("average \(String(describing: average)) != \(String(describing: scenario.average))")
        }
    }

    @Test("latest(from:) returns the most recent leg")
    func latest() {
        let records = [full(0, 1_000, 40), full(10, 1_400, 40), full(20, 1_800, 50)]
        let latest = Consumption.latest(from: records)

        #expect(latest?.startOdometer == 1_400)
        #expect(latest?.endOdometer == 1_800)
        #expect(latest?.liters == 50)
    }

    @Test("latest(from:) is nil without a closed leg")
    func latestWithoutInterval() {
        #expect(Consumption.latest(from: [full(0, 1_000, 40)]) == nil)
    }

    @Test("the leg carries the dates of the full tanks bounding it")
    func intervalDates() {
        let interval = Consumption.latest(from: [full(3, 1_000, 40), full(13, 1_400, 40)])

        #expect(interval?.startDate == day(3))
        #expect(interval?.endDate == day(13))
    }
}
