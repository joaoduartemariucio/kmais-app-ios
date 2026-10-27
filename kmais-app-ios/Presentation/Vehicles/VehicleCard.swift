import SwiftUI

struct VehicleCard: View {
    let row: VehicleListViewModel.Row

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                SymbolBadgeView(systemName: row.vehicle.kind.symbolName, tint: .accentColor, size: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(row.vehicle.name)
                        .font(.headline)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(row.vehicle.kind.label)
                        if let plate = row.vehicle.plate {
                            PlateView(plate: plate)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                if let level = row.stats.attentionLevel, level != .onTrack {
                    StatusCapsuleView(level: level)
                }
            }

            HStack(alignment: .top, spacing: 0) {
                figure(row.stats.currentOdometer.formattedKilometers(), caption: "Odometer")
                figure(row.stats.averageConsumption?.formattedConsumption, caption: "Consumption")
                figure(row.stats.cost.costPerKilometer?.formattedPerKilometer, caption: "Cost per km")
            }

            if let next = row.stats.nextDue {
                HStack(spacing: 8) {
                    Image(systemName: next.due.rule.kind.symbolName)
                        .foregroundStyle(next.status.level.color)
                    Text(next.due.rule.kind.label)
                        .fontWeight(.medium)
                    Spacer(minLength: 4)
                    Text(next.relativeDue)
                        .foregroundStyle(next.status.level == .onTrack ? .secondary : next.status.level.color)
                }
                .font(.footnote)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.fill.tertiary, in: .rect(cornerRadius: 10))
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private func figure(_ value: String?, caption: LocalizedStringResource) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value ?? "—")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PlateView: View {
    let plate: String

    var body: some View {
        Text(plate)
            .font(.caption2.monospaced().weight(.semibold))
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(.secondary, lineWidth: 1))
    }
}
