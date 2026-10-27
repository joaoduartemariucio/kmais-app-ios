import Foundation
import OSLog
import SwiftData
import SwiftUI

@MainActor
struct AppDependencies {
    let modelContainer: ModelContainer
    let vehicleRepository: VehicleRepository
    let fuelEntryRepository: FuelEntryRepository
    let serviceRepository: ServiceRepository
    let dateProvider: DateProvider
    let reminderScheduler: ReminderScheduler
    let reminderSync: ServiceReminderSync

    let isUsingFallbackStore: Bool

    init(modelContainer: ModelContainer, isUsingFallbackStore: Bool = false) {
        self.modelContainer = modelContainer
        self.isUsingFallbackStore = isUsingFallbackStore
        vehicleRepository = SwiftDataVehicleRepository(modelContainer: modelContainer)
        fuelEntryRepository = SwiftDataFuelEntryRepository(modelContainer: modelContainer)
        serviceRepository = SwiftDataServiceRepository(modelContainer: modelContainer)
        dateProvider = SystemDateProvider()
        reminderScheduler = UserNotificationReminderScheduler()
        reminderSync = ServiceReminderSync(
            vehicleRepository: vehicleRepository,
            fuelEntryRepository: fuelEntryRepository,
            serviceRepository: serviceRepository,
            scheduler: reminderScheduler,
            dateProvider: dateProvider
        )
    }

    static func live() -> AppDependencies {
        do {
            return try AppDependencies(modelContainer: KmaisSchema.container())
        } catch {
            let logger = Logger(
                subsystem: Bundle.main.bundleIdentifier ?? "br.com.joaoduartemariucio.kmais-app-ios",
                category: "startup"
            )
            logger.error("On-disk store unavailable, falling back to memory: \(error, privacy: .public)")
            return .inMemory(isUsingFallbackStore: true)
        }
    }

    static func inMemory(isUsingFallbackStore: Bool = false) -> AppDependencies {
        do {
            return try AppDependencies(
                modelContainer: KmaisSchema.container(inMemory: true),
                isUsingFallbackStore: isUsingFallbackStore
            )
        } catch {
            fatalError("Invalid schema: even the in-memory container failed. \(error)")
        }
    }
}

extension EnvironmentValues {
    @Entry var dependencies: AppDependencies = .inMemory()
}
