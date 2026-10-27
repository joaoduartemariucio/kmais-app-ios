import Charts
import SwiftUI

struct SpendingChartCard: View {
    let months: [VehicleTimeline.MonthSpending]

    private var fuelLabel: String { String(localized: "Fuel") }
    private var serviceLabel: String { String(localized: "Services") }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Spending").font(.headline)
                Spacer()
                Text("Last \(months.count) months")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Chart(months) { month in
                BarMark(
                    x: .value("Month", month.month, unit: .month),
                    y: .value("Amount", NSDecimalNumber(decimal: month.fuel).doubleValue)
                )
                .foregroundStyle(by: .value("Record type", fuelLabel))

                BarMark(
                    x: .value("Month", month.month, unit: .month),
                    y: .value("Amount", NSDecimalNumber(decimal: month.service).doubleValue)
                )
                .foregroundStyle(by: .value("Record type", serviceLabel))
            }
            .chartForegroundStyleScale([fuelLabel: Color.fuel, serviceLabel: Color.service])
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) {
                    AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                }
            }
            .chartLegend(position: .bottom, alignment: .leading)
            .frame(height: 170)
            .accessibilityLabel(Text("Spending per month"))
        }
        .padding(.vertical, 4)
    }
}
