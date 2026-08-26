import SwiftUI

struct FuelEntryRow: View {
    let entry: FuelEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label {
                    Text(entry.liters.formattedLiters())
                } icon: {
                    Image(systemName: "fuelpump.fill")
                }
                .font(.headline)

                Spacer()

                Text(entry.totalCost.formattedCurrency).font(.headline)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { details }
                VStack(alignment: .leading, spacing: 2) { details }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var details: some View {
        Text(entry.date.formattedDay)
        Text(entry.odometer.formattedKilometers())
        if entry.isFullTank {
            Text("Full tank")
        } else {
            Text("Partial fill")
        }
    }
}
