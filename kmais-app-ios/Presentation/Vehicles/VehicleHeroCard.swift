import SwiftUI

struct VehicleHeroCard: View {
    let vehicle: Vehicle
    let stats: VehicleStats

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            SymbolBadgeView(systemName: vehicle.kind.symbolName, tint: .accentColor, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(vehicle.kind.label)
                    if let plate = vehicle.plate {
                        PlateView(plate: plate)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(stats.currentOdometer.formattedKilometers())
                    .font(.title.weight(.bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if let pace = stats.kilometersPerMonth {
                    Label(pace.formattedKilometersPerMonth, systemImage: "speedometer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
