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

nonisolated extension Maintenance {
    static func due(
        rule: ServiceRule,
        vehicle: Vehicle,
        services: [ServiceEntry],
        history: [OdometerSample],
        calendar: Calendar = .current
    ) -> ServiceDue? {
        let last = services
            .filter { $0.kind == rule.kind }
            .max { $0.date < $1.date }

        let since = OdometerSample(
            date: last?.date ?? vehicle.createdAt,
            odometer: last?.odometer ?? vehicle.initialOdometer
        )

        guard let forecast = forecast(
            rule: rule,
            lastServiceDate: since.date,
            lastServiceOdometer: since.odometer,
            history: history,
            calendar: calendar
        ) else { return nil }

        return ServiceDue(rule: rule, forecast: forecast, since: since)
    }

    static func nextDue(
        rules: [ServiceRule],
        vehicle: Vehicle,
        services: [ServiceEntry],
        history: [OdometerSample],
        calendar: Calendar = .current
    ) -> ServiceDue? {
        rules
            .compactMap {
                due(rule: $0, vehicle: vehicle, services: services, history: history, calendar: calendar)
            }
            .min {
                $0.forecast.dueDate == $1.forecast.dueDate
                    ? $0.rule.kind.rawValue < $1.rule.kind.rawValue
                    : $0.forecast.dueDate < $1.forecast.dueDate
            }
    }
}

nonisolated extension Maintenance {
    static let dueSoonFraction = 0.15
    static let dueSoonKilometers = 300.0...1_000.0
    static let dueSoonDays = 15.0...30.0

    static func status(
        of due: ServiceDue,
        currentOdometer: Double,
        now: Date,
        calendar: Calendar = .current
    ) -> MaintenanceStatus {
        let today = calendar.startOfDay(for: now)
        let start = calendar.startOfDay(for: due.since.date)
        let estimated = calendar.startOfDay(for: due.forecast.dueDate)

        let remainingDays = days(from: today, to: estimated, calendar: calendar)
        let periodDays = max(1, days(from: start, to: estimated, calendar: calendar))
        let dateProgress = Double(periodDays - remainingDays) / Double(periodDays)
        var isDueSoon = Double(remainingDays) <= window(for: Double(periodDays), clampedTo: dueSoonDays)

        var isOverdue = false
        if let months = due.rule.monthInterval, months > 0,
           let calendarDueDate = calendar.date(byAdding: .month, value: months, to: start) {
            isOverdue = calendarDueDate < today
        }

        var remainingKilometers: Double?
        var distanceProgress = 0.0
        if let interval = due.rule.kilometerInterval, interval > 0 {
            let remaining = due.since.odometer + interval - currentOdometer
            remainingKilometers = remaining
            distanceProgress = (interval - remaining) / interval
            isOverdue = isOverdue || remaining <= 0
            isDueSoon = isDueSoon || remaining <= window(for: interval, clampedTo: dueSoonKilometers)
        }

        let level: MaintenanceStatus.Level = if isOverdue {
            .overdue
        } else if isDueSoon {
            .dueSoon
        } else {
            .onTrack
        }

        return MaintenanceStatus(
            level: level,
            progress: min(1, max(0, distanceProgress, dateProgress)),
            remainingKilometers: remainingKilometers,
            remainingDays: remainingDays
        )
    }

    private static func window(for length: Double, clampedTo range: ClosedRange<Double>) -> Double {
        min(range.upperBound, max(range.lowerBound, length * dueSoonFraction))
    }

    private static func days(from start: Date, to end: Date, calendar: Calendar) -> Int {
        calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }
}
