import SwiftUI

struct ServiceDueRow: View {
    let item: VehicleStats.DueItem

    private var level: MaintenanceStatus.Level { item.status.level }
    private var forecast: MaintenanceForecast { item.due.forecast }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                SymbolBadgeView(systemName: item.due.rule.kind.symbolName, tint: level.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.due.rule.kind.label).font(.headline)
                    Text(interval)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)
                StatusCapsuleView(level: level)
            }

            ProgressBarView(value: item.status.progress, tint: level.color)

            ViewThatFits(in: .horizontal) {
                HStack { details }
                VStack(alignment: .leading, spacing: 2) { details }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var details: some View {
        if let remaining = item.status.remainingKilometers {
            Label(remaining.formattedRemainingKilometers, systemImage: "road.lanes")
        }
        Spacer(minLength: 4)
        Label {
            Text(verbatim: "\(dueDate) · \(item.relativeDue)")
        } icon: {
            Image(systemName: "calendar")
        }
    }

    private var dueDate: String {
        forecast.trigger == .distance
            ? String(localized: "Around \(forecast.dueDate.formattedDay)")
            : forecast.dueDate.formattedDay
    }

    private var interval: String {
        let rule = item.due.rule
        switch (rule.kilometerInterval, rule.monthInterval) {
        case let (kilometers?, months?):
            return String(localized: "Every \(kilometers.formattedKilometers()) or \(months) months")
        case let (kilometers?, nil):
            return String(localized: "Every \(kilometers.formattedKilometers())")
        case let (nil, months?):
            return String(localized: "Every \(months) months")
        case (nil, nil):
            return ""
        }
    }
}
