import Foundation
import SwiftData

/// O único lugar do app que conhece as implementações concretas.
///
/// `Presentation` recebe tudo pelo tipo do protocolo; se algum ViewModel
/// precisar saber que existe SwiftData por trás, a composição vazou.
@MainActor
struct AppDependencies {
    let modelContainer: ModelContainer
    let vehicleRepository: VehicleRepository
    let fuelEntryRepository: FuelEntryRepository
    let serviceRepository: ServiceRepository
    let dateProvider: DateProvider
    let reminderScheduler: ReminderScheduler

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        vehicleRepository = SwiftDataVehicleRepository(modelContainer: modelContainer)
        fuelEntryRepository = SwiftDataFuelEntryRepository(modelContainer: modelContainer)
        serviceRepository = SwiftDataServiceRepository(modelContainer: modelContainer)
        dateProvider = SystemDateProvider()
        reminderScheduler = UserNotificationReminderScheduler()
    }

    static func live() -> AppDependencies {
        do {
            return AppDependencies(modelContainer: try KmaisSchema.container())
        } catch {
            fatalError("Não foi possível criar o ModelContainer: \(error)")
        }
    }
}
