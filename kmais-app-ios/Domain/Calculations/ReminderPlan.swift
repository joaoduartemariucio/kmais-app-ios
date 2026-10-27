import Foundation

nonisolated enum ReminderPlan {
    static let hourOfDay = 9

    static func reminders(
        for records: [VehicleRecords],
        now: Date,
        calendar: Calendar = .current
    ) -> [PlannedReminder] {
        let planned: [PlannedReminder] = records
            .filter { !$0.vehicle.isArchived }
            .flatMap { reminders(for: $0, now: now, calendar: calendar) }

        return planned.sorted { lhs, rhs in
            lhs.fireDate == rhs.fireDate ? lhs.id.uuidString < rhs.id.uuidString : lhs.fireDate < rhs.fireDate
        }
    }

    private static func reminders(for record: VehicleRecords, now: Date, calendar: Calendar) -> [PlannedReminder] {
        let history = Odometer.samples(vehicle: record.vehicle, fuel: record.fuel, services: record.services)
        let current = Odometer.current(history) ?? record.vehicle.initialOdometer

        return record.rules.compactMap { rule in
            guard let due = Maintenance.due(
                rule: rule,
                vehicle: record.vehicle,
                services: record.services,
                history: history,
                calendar: calendar
            ) else { return nil }

            let status = Maintenance.status(of: due, currentOdometer: current, now: now, calendar: calendar)
            guard let fireDate = fireDate(for: due, status: status, history: history, now: now, calendar: calendar)
            else { return nil }

            return PlannedReminder(
                vehicle: record.vehicle,
                due: due,
                status: status,
                currentOdometer: current,
                fireDate: fireDate
            )
        }
    }

    private static func fireDate(
        for due: ServiceDue,
        status: MaintenanceStatus,
        history: [OdometerSample],
        now: Date,
        calendar: Calendar
    ) -> Date? {
        if status.level == .overdue {
            let since = overdueSince(due: due, status: status, history: history) ?? now
            return overdueFireDate(since: since, now: now, calendar: calendar)
        }
        guard let dueDate = due.forecast.dueDate else { return nil }
        let onDueDay = morning(of: dueDate, calendar: calendar)
        return onDueDay > now ? onDueDay : nil
    }

    static func overdueSince(due: ServiceDue, status: MaintenanceStatus, history: [OdometerSample]) -> Date? {
        switch status.overdueBy {
        case .calendar:
            status.calendarDueDate
        case .distance:
            due.forecast.dueOdometer.flatMap { dueOdometer in
                history.sortedChronologically().first { $0.date >= due.since.date && $0.odometer >= dueOdometer }?.date
            }
        case nil:
            nil
        }
    }

    static let dailyOverdueDays = 7
    static let overdueRepeatDays = 7

    static func overdueFireDate(since: Date, now: Date, calendar: Calendar = .current) -> Date {
        let next = fireDate(for: since, now: now, calendar: calendar)
        let elapsed = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: since),
            to: calendar.startOfDay(for: next)
        ).day ?? 0
        guard elapsed > dailyOverdueDays else { return next }

        let offset = (overdueRepeatDays - elapsed % overdueRepeatDays) % overdueRepeatDays
        return calendar.date(byAdding: .day, value: offset, to: next) ?? next
    }

    static func fireDate(for dueDate: Date, now: Date, calendar: Calendar = .current) -> Date {
        let onDueDay = morning(of: dueDate, calendar: calendar)
        if onDueDay > now { return onDueDay }

        let today = morning(of: now, calendar: calendar)
        return today > now ? today : calendar.date(byAdding: .day, value: 1, to: today) ?? today
    }

    private static func morning(of date: Date, calendar: Calendar) -> Date {
        calendar.date(bySettingHour: hourOfDay, minute: 0, second: 0, of: date) ?? date
    }
}
