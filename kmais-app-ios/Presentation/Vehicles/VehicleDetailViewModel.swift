import Foundation

@MainActor
@Observable
final class VehicleDetailViewModel {

    enum State {
        case loading
        case loaded(Content)
        case failed(message: String)
    }

    struct Content {
        let stats: VehicleStats
        let sections: [VehicleTimeline.MonthSection]
        let rules: [ServiceRule]
    }

    let vehicle: Vehicle
    private(set) var state: State = .loading

    private let fuelEntryRepository: FuelEntryRepository
    private let serviceRepository: ServiceRepository
    private let dateProvider: DateProvider

    private var fuel: [FuelEntry] = []
    private var services: [ServiceEntry] = []

    init(
        vehicle: Vehicle,
        fuelEntryRepository: FuelEntryRepository,
        serviceRepository: ServiceRepository,
        dateProvider: DateProvider
    ) {
        self.vehicle = vehicle
        self.fuelEntryRepository = fuelEntryRepository
        self.serviceRepository = serviceRepository
        self.dateProvider = dateProvider
    }

    func load() async {
        do {
            let fuel = try await fuelEntryRepository.entries(vehicleID: vehicle.id)
            let services = try await serviceRepository.entries(vehicleID: vehicle.id)
            let rules = try await serviceRepository.rules(vehicleID: vehicle.id)

            self.fuel = fuel
            self.services = services

            state = .loaded(
                Content(
                    stats: VehicleStats(
                        vehicle: vehicle,
                        fuel: fuel,
                        services: services,
                        rules: rules,
                        calendar: dateProvider.calendar
                    ),
                    sections: VehicleTimeline.sections(
                        fuel: fuel,
                        services: services,
                        calendar: dateProvider.calendar
                    ),
                    rules: rules
                )
            )
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    var rules: [ServiceRule] {
        if case .loaded(let content) = state { content.rules } else { [] }
    }

    func odometerReadings(excluding item: VehicleTimeline.Item? = nil) -> [OdometerSample] {
        Odometer.samples(
            vehicle: vehicle,
            fuel: fuel.filter { $0.id != item?.id },
            services: services.filter { $0.id != item?.id }
        )
    }

    func delete(_ item: VehicleTimeline.Item) async {
        do {
            switch item {
            case .fuel(let entry):
                try await fuelEntryRepository.delete(id: entry.id)
            case .service(let entry):
                try await serviceRepository.deleteEntry(id: entry.id)
            }
            await load()
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }
}
