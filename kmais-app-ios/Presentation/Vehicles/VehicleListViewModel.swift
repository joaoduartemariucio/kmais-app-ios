import Foundation

@MainActor
@Observable
final class VehicleListViewModel {

    enum Scope {
        case active
        case archived
    }

    enum State {
        case loading
        case loaded([Row])
        case failed(message: String)
    }

    struct Row: Identifiable {
        let vehicle: Vehicle
        let stats: VehicleStats

        var id: UUID { vehicle.id }
    }

    struct Overview {
        let vehicleCount: Int
        let spentThisMonth: Decimal
        let overdueCount: Int
        let dueSoonCount: Int
    }

    let scope: Scope
    private(set) var state: State = .loading

    private let vehicleRepository: VehicleRepository
    private let fuelEntryRepository: FuelEntryRepository
    private let serviceRepository: ServiceRepository
    private let dateProvider: DateProvider
    private let reminders: ServiceReminderSync?

    init(
        scope: Scope,
        vehicleRepository: VehicleRepository,
        fuelEntryRepository: FuelEntryRepository,
        serviceRepository: ServiceRepository,
        dateProvider: DateProvider,
        reminders: ServiceReminderSync? = nil
    ) {
        self.scope = scope
        self.vehicleRepository = vehicleRepository
        self.fuelEntryRepository = fuelEntryRepository
        self.serviceRepository = serviceRepository
        self.dateProvider = dateProvider
        self.reminders = reminders
    }

    var overview: Overview? {
        guard case let .loaded(rows) = state, !rows.isEmpty else { return nil }
        let levels = rows.flatMap { $0.stats.dues.map(\.status.level) }
        return Overview(
            vehicleCount: rows.count,
            spentThisMonth: rows.reduce(.zero) { $0 + $1.stats.spentThisMonth },
            overdueCount: levels.filter { $0 == .overdue }.count,
            dueSoonCount: levels.filter { $0 == .dueSoon }.count
        )
    }

    func load() async {
        do {
            let vehicles = try await vehicleRepository
                .all(includingArchived: scope == .archived)
                .filter { scope == .archived ? $0.isArchived : !$0.isArchived }

            var rows: [Row] = []
            for vehicle in vehicles {
                let fuel = try await fuelEntryRepository.entries(vehicleID: vehicle.id)
                let services = try await serviceRepository.entries(vehicleID: vehicle.id)
                let rules = try await serviceRepository.rules(vehicleID: vehicle.id)
                rows.append(
                    Row(
                        vehicle: vehicle,
                        stats: VehicleStats(
                            vehicle: vehicle,
                            fuel: fuel,
                            services: services,
                            rules: rules,
                            now: dateProvider.now,
                            calendar: dateProvider.calendar
                        )
                    )
                )
            }
            state = .loaded(rows)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
        await reminders?.sync()
    }

    func setArchived(_ isArchived: Bool, on vehicle: Vehicle) async {
        do {
            try await vehicleRepository.setArchived(isArchived, vehicleID: vehicle.id)
            await load()
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }
}
