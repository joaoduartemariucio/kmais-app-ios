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

    let scope: Scope
    private(set) var state: State = .loading

    private let vehicleRepository: VehicleRepository
    private let fuelEntryRepository: FuelEntryRepository
    private let serviceRepository: ServiceRepository

    init(
        scope: Scope,
        vehicleRepository: VehicleRepository,
        fuelEntryRepository: FuelEntryRepository,
        serviceRepository: ServiceRepository
    ) {
        self.scope = scope
        self.vehicleRepository = vehicleRepository
        self.fuelEntryRepository = fuelEntryRepository
        self.serviceRepository = serviceRepository
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
                rows.append(
                    Row(
                        vehicle: vehicle,
                        stats: VehicleStats(vehicle: vehicle, fuel: fuel, services: services)
                    )
                )
            }
            state = .loaded(rows)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
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
