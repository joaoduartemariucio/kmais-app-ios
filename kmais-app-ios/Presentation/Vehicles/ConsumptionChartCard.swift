import Charts
import SwiftUI

struct ConsumptionChartCard: View {
    let intervals: [ConsumptionInterval]
    let average: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Consumption").font(.headline)
                Spacer()
                if let average {
                    Text(String(localized: "Average \(average.formattedConsumption)"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Chart {
                ForEach(intervals, id: \.self) { interval in
                    LineMark(
                        x: .value("Date", interval.endDate),
                        y: .value("km/L", interval.kilometersPerLiter)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color.fuel)

                    PointMark(
                        x: .value("Date", interval.endDate),
                        y: .value("km/L", interval.kilometersPerLiter)
                    )
                    .foregroundStyle(Color.fuel)
                    .symbolSize(30)
                }

                if let average {
                    RuleMark(y: .value("Average", average))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(.secondary)
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) {
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .frame(height: 160)
            .accessibilityLabel(Text("Consumption over time"))
        }
        .padding(.vertical, 4)
    }
}
