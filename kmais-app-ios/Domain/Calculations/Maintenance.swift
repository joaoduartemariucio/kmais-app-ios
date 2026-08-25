import Foundation

nonisolated enum Maintenance {
    static let averageDaysPerMonth = 365.25 / 12

    static func averageKilometersPerDay(_ samples: [OdometerSample]) -> Double? {
        let sorted = samples.sortedChronologically()
        guard let first = sorted.first, let last = sorted.last else { return nil }

        let days = last.date.timeIntervalSince(first.date) / 86_400
        let kilometers = last.odometer - first.odometer
        guard days > 0, kilometers > 0 else { return nil }

        return kilometers / days
    }

    static func averageKilometersPerMonth(_ samples: [OdometerSample]) -> Double? {
        averageKilometersPerDay(samples).map { $0 * averageDaysPerMonth }
    }

    static func forecast(
        rule: ServiceRule,
        lastServiceDate: Date,
        lastServiceOdometer: Double,
        history: [OdometerSample],
        calendar: Calendar = .current
    ) -> MaintenanceForecast? {
        let kilometersPerDay = averageKilometersPerDay(history)
        let kilometersPerMonth = kilometersPerDay.map { $0 * averageDaysPerMonth }

        var dueOdometer: Double?
        var dateByDistance: Date?

        if let interval = rule.kilometerInterval, interval > 0 {
            let due = lastServiceOdometer + interval
            dueOdometer = due

            if let kilometersPerDay, let current = history.sortedChronologically().last {
                let days = (due - current.odometer) / kilometersPerDay
                if days.isFinite, abs(days) < 36_525 {
                    dateByDistance = calendar.date(
                        byAdding: .day,
                        value: Int(days.rounded()),
                        to: current.date
                    )
                }
            }
        }

        var dateByCalendar: Date?
        if let months = rule.monthInterval, months > 0 {
            dateByCalendar = calendar.date(byAdding: .month, value: months, to: lastServiceDate)
        }

        let dueDate: Date
        let trigger: MaintenanceForecast.Trigger
        switch (dateByDistance, dateByCalendar) {
        case let (byDistance?, byCalendar?):
            dueDate = min(byDistance, byCalendar)
            trigger = byDistance <= byCalendar ? .distance : .calendar
        case let (byDistance?, nil):
            dueDate = byDistance
            trigger = .distance
        case let (nil, byCalendar?):
            dueDate = byCalendar
            trigger = .calendar
        case (nil, nil):
            return nil
        }

        return MaintenanceForecast(
            dueDate: dueDate,
            trigger: trigger,
            dueOdometer: dueOdometer,
            averageKilometersPerMonth: kilometersPerMonth
        )
    }
}
