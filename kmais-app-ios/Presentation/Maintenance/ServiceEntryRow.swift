import SwiftUI

struct ServiceEntryRow: View {
    let entry: ServiceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label {
                    Text(entry.kind.label)
                } icon: {
                    Image(systemName: entry.kind.symbolName)
                }
                .font(.headline)

                Spacer()

                Text(entry.cost.formattedCurrency).font(.headline)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { details }
                VStack(alignment: .leading, spacing: 2) { details }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !entry.notes.isEmpty {
                Text(entry.notes).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var details: some View {
        Text(entry.date.formattedDay)
        Text(entry.odometer.formattedKilometers())
    }
}
