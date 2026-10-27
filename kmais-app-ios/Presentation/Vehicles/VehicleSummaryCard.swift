import SwiftUI

struct VehicleSummaryCard: View {
    let stats: VehicleStats

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            MetricTileCard(
                title: "Average consumption",
                value: stats.averageConsumption?.formattedConsumption,
                caption: stats.latestConsumption.map {
                    String(localized: "Last: \($0.kilometersPerLiter.formattedConsumption)")
                },
                systemImage: "gauge.with.dots.needle.67percent",
                tint: .fuel
            )
            MetricTileCard(
                title: "Cost per km",
                value: stats.cost.costPerKilometer?.formattedPerKilometer,
                caption: stats.cost.distance > 0
                    ? String(localized: "Over \(stats.cost.distance.formattedKilometers())")
                    : nil,
                systemImage: "road.lanes",
                tint: .accentColor
            )
            MetricTileCard(
                title: "Total spent",
                value: stats.cost.totalCost.formattedCurrency,
                caption: breakdown,
                systemImage: "creditcard",
                tint: .service
            )
            MetricTileCard(
                title: "This month",
                value: stats.spentThisMonth.formattedCurrency,
                caption: stats.lastPricePerLiter.map {
                    String(localized: "Last fuel price \($0.formattedPerLiter)")
                },
                systemImage: "calendar",
                tint: .orange
            )
        }
    }

    private var breakdown: String {
        let fuel = stats.cost.fuelCost.formattedCurrency
        let services = stats.cost.serviceCost.formattedCurrency
        return String(localized: "Fuel \(fuel) · Services \(services)")
    }
}
