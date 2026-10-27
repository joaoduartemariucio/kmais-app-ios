import SwiftUI

struct GarageOverviewCard: View {
    let overview: VehicleListViewModel.Overview

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Spent this month")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(overview.spentThisMonth.formattedCurrency)
                    .font(.largeTitle.weight(.bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { chips }
                VStack(alignment: .leading, spacing: 8) { chips }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var chips: some View {
        chip(
            Text("\(overview.vehicleCount) vehicles"),
            systemImage: "car.2.fill",
            tint: .accentColor
        )
        if overview.overdueCount > 0 {
            chip(Text("\(overview.overdueCount) overdue"), systemImage: "exclamationmark.triangle.fill", tint: .red)
        }
        if overview.dueSoonCount > 0 {
            chip(Text("\(overview.dueSoonCount) due soon"), systemImage: "clock.fill", tint: .orange)
        }
        if overview.overdueCount == 0, overview.dueSoonCount == 0 {
            chip(Text("Maintenance up to date"), systemImage: "checkmark.seal.fill", tint: .green)
        }
    }

    private func chip(_ text: Text, systemImage: String, tint: Color) -> some View {
        Label { text } icon: { Image(systemName: systemImage) }
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: .capsule)
            .lineLimit(1)
            .fixedSize()
    }
}
