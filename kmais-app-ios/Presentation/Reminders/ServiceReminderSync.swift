import Foundation
import OSLog

@MainActor
final class ServiceReminderSync {
    private let vehicleRepository: VehicleRepository
    private let fuelEntryRepository: FuelEntryRepository
    private let serviceRepository: ServiceRepository
    private let scheduler: ReminderScheduler
    private let dateProvider: DateProvider

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "br.com.joaoduartemariucio.kmais-app-ios",
        category: "reminders"
    )

    init(
        vehicleRepository: VehicleRepository,
        fuelEntryRepository: FuelEntryRepository,
        serviceRepository: ServiceRepository,
        scheduler: ReminderScheduler,
        dateProvider: DateProvider
    ) {
        self.vehicleRepository = vehicleRepository
        self.fuelEntryRepository = fuelEntryRepository
        self.serviceRepository = serviceRepository
        self.scheduler = scheduler
        self.dateProvider = dateProvider
    }

    func sync() async {
        do {
            let planned = try await ReminderPlan.reminders(
                for: records(),
                now: dateProvider.now,
                calendar: dateProvider.calendar
            )

            let wanted = Set(planned.map(\.id))
            for id in await scheduler.pendingIdentifiers() where !wanted.contains(id) {
                try await scheduler.cancel(id: id)
            }

            guard !planned.isEmpty, try await scheduler.requestAuthorization() else { return }
            for reminder in planned {
                try await scheduler.schedule(Self.reminder(for: reminder))
            }
        } catch {
            Self.logger.error("Could not sync service reminders: \(error, privacy: .public)")
        }
    }

    private func records() async throws -> [VehicleRecords] {
        var records: [VehicleRecords] = []
        for vehicle in try await vehicleRepository.all(includingArchived: false) {
            try await records.append(
                VehicleRecords(
                    vehicle: vehicle,
                    fuel: fuelEntryRepository.entries(vehicleID: vehicle.id),
                    services: serviceRepository.entries(vehicleID: vehicle.id),
                    rules: serviceRepository.rules(vehicleID: vehicle.id)
                )
            )
        }
        return records
    }

    static func reminder(for planned: PlannedReminder) -> Reminder {
        let forecast = planned.due.forecast
        let status = planned.status

        let body = if status.overdueBy == .distance, let odometer = forecast.dueOdometer {
            String(
                localized: "Was due at \(odometer.formattedKilometers()) (last reading \(planned.currentOdometer.formattedKilometers()))."
            )
        } else if status.overdueBy == .calendar, let date = status.calendarDueDate {
            String(localized: "Overdue since \(date.formattedFullDate).")
        } else if let date = forecast.dueDate {
            if forecast.trigger == .distance, let odometer = forecast.dueOdometer {
                String(localized: "Due at \(odometer.formattedKilometers()), around \(date.formattedFullDate).")
            } else {
                String(localized: "Due on \(date.formattedFullDate).")
            }
        } else {
            String(localized: "Due at \((forecast.dueOdometer ?? 0).formattedKilometers()).")
        }

        return Reminder(
            id: planned.id,
            title: "\(planned.vehicle.name): \(String(localized: planned.due.rule.kind.label))",
            body: body,
            fireDate: planned.fireDate
        )
    }
}
