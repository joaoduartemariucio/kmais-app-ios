import SwiftUI

struct FuelEntryRow: View {
    let entry: FuelEntry
    var consumption: Double?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SymbolBadgeView(systemName: "fuelpump.fill", tint: .fuel)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(entry.liters.formattedLiters())
                        .font(.headline)
                        .monospacedDigit()
                    Text(entry.pricePerLiter.formattedPerLiter)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    Text(entry.totalCost.formattedCurrency)
                        .font(.headline)
                        .monospacedDigit()
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        reading
                        Spacer(minLength: 4)
                        tags
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        reading
                        HStack(spacing: 6) { tags }
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var reading: some View {
        HStack(spacing: 8) {
            Text(entry.date.formattedDay)
            Text(entry.odometer.formattedKilometers()).monospacedDigit()
        }
        .lineLimit(1)
        .fixedSize()
    }

    @ViewBuilder
    private var tags: some View {
        if let consumption {
            tag(consumption.formattedConsumption, tint: .fuel)
        }
        if entry.isFullTank {
            tag(String(localized: "Full tank"), tint: .secondary)
        } else {
            tag(String(localized: "Partial fill"), tint: .secondary)
        }
    }

    private func tag(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.quaternary.opacity(0.6), in: .capsule)
            .lineLimit(1)
            .fixedSize()
    }
}
