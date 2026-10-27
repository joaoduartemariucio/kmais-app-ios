import SwiftUI

struct ServiceEntryRow: View {
    let entry: ServiceEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SymbolBadgeView(systemName: entry.kind.symbolName, tint: .service)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(entry.kind.label).font(.headline)
                    Spacer(minLength: 8)
                    Text(entry.cost.formattedCurrency)
                        .font(.headline)
                        .monospacedDigit()
                }

                HStack(spacing: 8) {
                    Text(entry.date.formattedDay)
                    Text(entry.odometer.formattedKilometers()).monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
