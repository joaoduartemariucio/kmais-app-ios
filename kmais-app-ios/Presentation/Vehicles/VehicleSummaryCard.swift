import SwiftUI

struct VehicleSummaryCard: View {
    let stats: VehicleStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            metric("Odometer", value: stats.currentOdometer.formattedKilometers())

            metric(
                "Average consumption",
                value: stats.averageConsumption.map { $0.formattedConsumption }
            )

            metric(
                "Cost per kilometer",
                value: stats.cost.costPerKilometer.map { $0.formattedCurrency }
            )

            metric("Total spent", value: stats.cost.totalCost.formattedCurrency)

            if let due = stats.nextDue {
                metric(
                    due.rule.kind.label,
                    value: due.forecast.dueDate.formattedFullDate,
                    caption: due.forecast.dueOdometer.map { $0.formattedKilometers() }
                )
            } else {
                metric("Next service", value: nil)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func metric(
        _ title: LocalizedStringResource,
        value: String?,
        caption: String? = nil
    ) -> some View {
        LabeledContent {
            VStack(alignment: .trailing) {
                Text(value ?? String(localized: "Not enough data"))
                    .foregroundStyle(value == nil ? .secondary : .primary)
                if let caption {
                    Text(caption).font(.caption).foregroundStyle(.secondary)
                }
            }
        } label: {
            Text(title)
        }
        .accessibilityElement(children: .combine)
    }
}
