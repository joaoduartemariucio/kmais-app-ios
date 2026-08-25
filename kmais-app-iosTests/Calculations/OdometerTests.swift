import Foundation
import Testing
@testable import kmais_app_ios

@Suite("Odômetro")
struct OdometerTests {

    struct Scenario: Sendable, CustomTestStringConvertible {
        let name: String
        let samples: [OdometerSample]
        let expected: Double?

        var testDescription: String { name }
    }

    static let scenarios: [Scenario] = [
        Scenario(name: "histórico vazio", samples: [], expected: nil),
        Scenario(name: "uma amostra", samples: [sample(0, 10_000)], expected: 10_000),
        Scenario(
            name: "a leitura mais recente vence",
            samples: [sample(0, 10_000), sample(30, 12_000), sample(10, 11_000)],
            expected: 12_000
        ),
        Scenario(
            name: "odômetro que retrocede devolve o mais recente, não o maior",
            samples: [sample(0, 10_000), sample(10, 15_000), sample(20, 12_000)],
            expected: 12_000
        ),
        Scenario(
            name: "empate de data resolve pelo maior odômetro",
            samples: [sample(0, 10_000), sample(10, 11_000), sample(10, 11_500)],
            expected: 11_500
        )
    ]

    @Test("current(_:) por cenário", arguments: scenarios)
    func scenario(_ scenario: Scenario) {
        #expect(Odometer.current(scenario.samples) == scenario.expected)
    }

    @Test("samples(vehicle:fuel:services:) inclui o cadastro do veículo")
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
        // Sem nenhum registro, o odômetro do veículo ainda é conhecido.
        #expect(Odometer.current(Odometer.samples(vehicle: vehicle, fuel: [], services: [])) == 50_000)
    }
}
