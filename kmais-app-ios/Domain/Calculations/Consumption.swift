import Foundation

enum Consumption {
    static func intervals(from records: [FuelEntry]) -> [ConsumptionInterval] {
        var intervals: [ConsumptionInterval] = []
        var open: FuelEntry?
        var litersSinceOpen = 0.0

        for record in records.sortedChronologically() where record.liters > 0 {
            guard let start = open else {
                if record.isFullTank { open = record }
                continue
            }

            litersSinceOpen += record.liters
            guard record.isFullTank else { continue }

            let interval = ConsumptionInterval(
                startDate: start.date,
                endDate: record.date,
                startOdometer: start.odometer,
                endOdometer: record.odometer,
                liters: litersSinceOpen
            )
            if interval.distance > 0 {
                intervals.append(interval)
            }

            open = record
            litersSinceOpen = 0
        }

        return intervals
    }

    static func latest(from records: [FuelEntry]) -> ConsumptionInterval? {
        intervals(from: records).last
    }

    static func average(from records: [FuelEntry]) -> Double? {
        let intervals = intervals(from: records)
        guard !intervals.isEmpty else { return nil }

        let liters = intervals.reduce(0) { $0 + $1.liters }
        guard liters > 0 else { return nil }

        return intervals.reduce(0) { $0 + $1.distance } / liters
    }

    static func anomalies(in records: [FuelEntry]) -> [ConsumptionAnomaly] {
        var anomalies: [ConsumptionAnomaly] = []
        var previous: FuelEntry?

        for record in records.sortedChronologically() {
            defer { previous = record }

            if record.liters <= 0 {
                anomalies.append(ConsumptionAnomaly(record: record, kind: .nonPositiveLiters))
            }

            guard let previous else { continue }

            if record.odometer < previous.odometer {
                anomalies.append(
                    ConsumptionAnomaly(
                        record: record,
                        kind: .odometerWentBackwards(previous: previous.odometer)
                    )
                )
            } else if record.odometer == previous.odometer {
                let isDuplicate = record.date == previous.date
                    && record.liters == previous.liters
                    && record.pricePerLiter == previous.pricePerLiter
                anomalies.append(
                    ConsumptionAnomaly(
                        record: record,
                        kind: isDuplicate
                            ? .duplicate(of: previous.id)
                            : .odometerUnchanged(previous: previous.odometer)
                    )
                )
            }
        }

        return anomalies
    }
}
