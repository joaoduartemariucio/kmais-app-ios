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

        return record.rules.compactMap { rule in
            let due = Maintenance.due(
                rule: rule,
                vehicle: record.vehicle,
                services: record.services,
                history: history,
                calendar: calendar
            )
            return due.map { due in
                PlannedReminder(
                    vehicle: record.vehicle,
                    due: due,
                    fireDate: fireDate(for: due.forecast.dueDate, now: now, calendar: calendar),
                    isOverdue: calendar.startOfDay(for: due.forecast.dueDate) < calendar.startOfDay(for: now)
                )
            }
        }
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
