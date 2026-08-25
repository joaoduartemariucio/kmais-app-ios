import Foundation
import Testing
@testable import kmais_app_ios

@Suite("Cost per kilometer")
struct CostTests {
    @Test("no records: everything zeroed and no cost per kilometer")
    func empty() {
        let summary = Cost.summary(fuel: [], services: [])

        #expect(summary.totalCost == 0)
        #expect(summary.distance == 0)
        #expect(summary.costPerKilometer == nil)
    }

    @Test("a single record has a known spend but no cost per kilometer")
    func singleRecord() {
        let summary = Cost.summary(fuel: [full(0, 1_000, 40, price: 5)], services: [])

        #expect(summary.fuelCost == 200)
        #expect(summary.distance == 0)
        #expect(summary.costPerKilometer == nil)
    }

    @Test("records all at the same odometer define no distance")
    func zeroDistance() {
        let summary = Cost.summary(
            fuel: [full(0, 1_000, 40), full(10, 1_000, 40)],
            services: []
        )

        #expect(summary.distance == 0)
        #expect(summary.costPerKilometer == nil)
    }

    @Test("fuel and services add up in the cost per kilometer")
    func fuelAndServices() {
        let summary = Cost.summary(
            fuel: [
                full(0, 1_000, 40, price: 5),
                full(10, 1_400, 40, price: Decimal(string: "5.50")!)
            ],
            services: [service(5, 1_200, 100)]
        )

        #expect(summary.fuelCost == 420)
        #expect(summary.serviceCost == 100)
        #expect(summary.totalCost == 520)
        #expect(summary.distance == 400)
        #expect(summary.costPerKilometer == Decimal(string: "1.30")!)
    }

    @Test("a service can be the far end of the odometer span")
    func serviceExtendsSpan() {
        let summary = Cost.summary(
            fuel: [full(0, 1_000, 40), full(10, 1_400, 40)],
            services: [service(20, 1_600, 200)]
        )

        #expect(summary.distance == 600)
    }

    @Test("summing cents does not accumulate floating-point error")
    func decimalIsExact() {
        let dime = Decimal(string: "0.10")!
        let fuel = (0..<10).map { full($0, Double(1_000 + $0 * 100), 1, price: dime) }

        let summary = Cost.summary(fuel: fuel, services: [])
        let viaDouble = (0..<10).reduce(0.0) { total, _ in total + 0.1 }

        #expect(summary.fuelCost == 1)
        #expect(viaDouble != 1)
    }

    @Test("the period is whatever the arrays carry: filtering by date changes the result")
    func periodComesFromInput() {
        let everything = [full(0, 1_000, 40), full(10, 1_400, 40), full(20, 1_800, 40)]
        let recent = everything.filter { $0.date >= day(10) }

        let whole = Cost.summary(fuel: everything, services: [])
        let window = Cost.summary(fuel: recent, services: [])

        #expect(whole.distance == 800)
        #expect(window.distance == 400)
    }
}
