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
        let spending: [VehicleTimeline.MonthSpending]
        let rules: [ServiceRule]
    }

    static let spendingMonths = 6

    let vehicle: Vehicle
    private(set) var state: State = .loading
    var filter: VehicleTimeline.Filter = .all

    private let fuelEntryRepository: FuelEntryRepository
    private let serviceRepository: ServiceRepository
    private let dateProvider: DateProvider
    private let reminders: ServiceReminderSync?

    private var fuel: [FuelEntry] = []
    private var services: [ServiceEntry] = []

    init(
        vehicle: Vehicle,
        fuelEntryRepository: FuelEntryRepository,
        serviceRepository: ServiceRepository,
        dateProvider: DateProvider,
        reminders: ServiceReminderSync? = nil
    ) {
        self.vehicle = vehicle
        self.fuelEntryRepository = fuelEntryRepository
        self.serviceRepository = serviceRepository
        self.dateProvider = dateProvider
        self.reminders = reminders
    }

    func load() async {
        do {
            let fuel = try await fuelEntryRepository.entries(vehicleID: vehicle.id)
            let services = try await serviceRepository.entries(vehicleID: vehicle.id)
            let rules = try await serviceRepository.rules(vehicleID: vehicle.id)

            self.fuel = fuel
            self.services = services

            let calendar = dateProvider.calendar
            let now = dateProvider.now
            let sections = VehicleTimeline.sections(fuel: fuel, services: services, calendar: calendar)

            state = .loaded(
                Content(
                    stats: VehicleStats(
                        vehicle: vehicle,
                        fuel: fuel,
                        services: services,
                        rules: rules,
                        now: now,
                        calendar: calendar
                    ),
                    sections: sections,
                    spending: VehicleTimeline.spending(
                        sections,
                        months: Self.spendingMonths,
                        endingAt: now,
                        calendar: calendar
                    ),
                    rules: rules
                )
            )
        } catch {
            state = .failed(message: error.localizedDescription)
        }
        await reminders?.sync()
    }

    var visibleSections: [VehicleTimeline.MonthSection] {
        guard case let .loaded(content) = state else { return [] }
        return content.sections.compactMap { $0.filtered(by: filter) }
    }

    var hasHistory: Bool {
        if case let .loaded(content) = state { !content.sections.isEmpty } else { false }
    }

    var lastPricePerLiter: Decimal? {
        if case let .loaded(content) = state { content.stats.lastPricePerLiter } else { nil }
    }

    var rules: [ServiceRule] {
        if case let .loaded(content) = state { content.rules } else { [] }
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
            case let .fuel(entry):
                try await fuelEntryRepository.delete(id: entry.id)
            case let .service(entry):
                try await serviceRepository.deleteEntry(id: entry.id)
            }
            await load()
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }
}
