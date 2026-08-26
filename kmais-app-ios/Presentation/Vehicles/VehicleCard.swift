import SwiftUI

struct VehicleCard: View {
    let row: VehicleListViewModel.Row

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(row.vehicle.name).font(.headline)
            } icon: {
                Image(systemName: row.vehicle.kind.symbolName)
                    .foregroundStyle(.tint)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) { details }
                VStack(alignment: .leading, spacing: 4) { details }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var details: some View {
        Text(row.vehicle.kind.label)
        Text(row.stats.currentOdometer.formattedKilometers())
        if let consumption = row.stats.latestConsumption {
            Text(consumption.kilometersPerLiter.formattedConsumption)
        } else {
            Text("No consumption yet")
        }
    }
}
