import Foundation
import Testing
@testable import kmais_app_ios

@Suite("Odometer")
struct OdometerTests {
    struct Scenario: Sendable, CustomTestStringConvertible {
        let name: String
        let samples: [OdometerSample]
        let expected: Double?

        var testDescription: String { name }
    }

    static let scenarios: [Scenario] = [
        Scenario(name: "empty history", samples: [], expected: nil),
        Scenario(name: "a single sample", samples: [sample(0, 10_000)], expected: 10_000),
        Scenario(
            name: "the most recent reading wins",
            samples: [sample(0, 10_000), sample(30, 12_000), sample(10, 11_000)],
            expected: 12_000
        ),
        Scenario(
            name: "a backwards odometer returns the most recent, not the highest",
            samples: [sample(0, 10_000), sample(10, 15_000), sample(20, 12_000)],
            expected: 12_000
        ),
        Scenario(
            name: "a date tie resolves by the higher odometer",
            samples: [sample(0, 10_000), sample(10, 11_000), sample(10, 11_500)],
            expected: 11_500
        )
    ]

    @Test("current(_:) per scenario", arguments: scenarios)
    func scenario(_ scenario: Scenario) {
        #expect(Odometer.current(scenario.samples) == scenario.expected)
    }

    @Test("neighbors(of:in:) brackets a date between the readings around it")
    func neighborsInTheMiddle() {
        let samples = [sample(0, 10_000), sample(10, 11_000), sample(20, 12_000)]

        let neighbors = Odometer.neighbors(of: day(15), in: samples)

        #expect(neighbors == OdometerNeighbors(previous: 11_000, next: 12_000))
    }

    @Test("neighbors(of:in:) has no next reading after the most recent one")
    func neighborsAtTheEnd() {
        let neighbors = Odometer.neighbors(of: day(30), in: [sample(0, 10_000), sample(10, 11_000)])

        #expect(neighbors == OdometerNeighbors(previous: 11_000, next: nil))
    }

    @Test("neighbors(of:in:) has no previous reading before the first one")
    func neighborsAtTheStart() {
        let neighbors = Odometer.neighbors(of: day(-5), in: [sample(0, 10_000)])

        #expect(neighbors == OdometerNeighbors(previous: nil, next: 10_000))
    }

    @Test("samples(vehicle:fuel:services:) includes the vehicle registration")
    func samplesIncludeRegistration() {
        let vehicle = Vehicle(
            id: testVehicleID,
            name: "Gol",
            initialOdometer: 50_000,
            createdAt: day(0)
        )

        let samples = Odometer.samples(
            vehicle: vehicle,
            fuel: [full(10, 51_000, 40)],
            services: [service(20, 52_000, 300)]
        )

        #expect(samples.count == 3)
        #expect(Odometer.current(samples) == 52_000)
        #expect(Odometer.current(Odometer.samples(vehicle: vehicle, fuel: [], services: [])) == 50_000)
    }
}
