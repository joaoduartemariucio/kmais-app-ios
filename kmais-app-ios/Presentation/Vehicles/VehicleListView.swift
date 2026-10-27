import SwiftUI

struct VehicleListView: View {
    let scope: VehicleListViewModel.Scope

    @Environment(\.dependencies) private var dependencies
    @State private var viewModel: VehicleListViewModel?
    @State private var sheet: Sheet?

    private enum Sheet: Identifiable {
        case create
        case edit(Vehicle)

        var id: String {
            switch self {
            case .create: "create"
            case let .edit(vehicle): vehicle.id.uuidString
            }
        }
    }

    var body: some View {
        Group {
            if let viewModel {
                content(for: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(scope == .active ? "Vehicles" : "Archived")
        .toolbar {
            if scope == .active {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add vehicle", systemImage: "plus") { sheet = .create }
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(value: AppRoute.archivedVehicles) {
                        Label("Archived", systemImage: "archivebox")
                    }
                }
            }
        }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .create:
                VehicleFormView(mode: .create) { Task { await viewModel?.load() } }
            case let .edit(vehicle):
                VehicleFormView(mode: .edit(vehicle)) { Task { await viewModel?.load() } }
            }
        }
        .task {
            if viewModel == nil {
                viewModel = VehicleListViewModel(
                    scope: scope,
                    vehicleRepository: dependencies.vehicleRepository,
                    fuelEntryRepository: dependencies.fuelEntryRepository,
                    serviceRepository: dependencies.serviceRepository,
                    dateProvider: dependencies.dateProvider,
                    reminders: dependencies.reminderSync
                )
            }
            await viewModel?.load()
        }
    }

    @ViewBuilder
    private func content(for viewModel: VehicleListViewModel) -> some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case let .failed(message):
            EmptyStateView(
                title: "Could not load vehicles",
                systemImage: "exclamationmark.triangle",
                message: LocalizedStringKey(message)
            )
        case let .loaded(rows):
            if rows.isEmpty {
                emptyState
            } else {
                List {
                    if scope == .active, let overview = viewModel.overview {
                        Section {
                            GarageOverviewCard(overview: overview)
                        }
                    }

                    Section {
                        ForEach(rows) { row in
                            vehicleRow(row, viewModel: viewModel)
                        }
                    }
                    .listSectionSpacing(.compact)
                }
                .refreshable { await viewModel.load() }
            }
        }
    }

    private func vehicleRow(_ row: VehicleListViewModel.Row, viewModel: VehicleListViewModel) -> some View {
        NavigationLink(value: AppRoute.vehicleDetail(row.vehicle)) {
            VehicleCard(row: row)
        }
        .swipeActions(edge: .trailing) {
            archiveButton(for: row.vehicle, viewModel: viewModel)
        }
        .swipeActions(edge: .leading) {
            Button("Edit", systemImage: "pencil") { sheet = .edit(row.vehicle) }
        }
        .contextMenu {
            Button("Edit", systemImage: "pencil") { sheet = .edit(row.vehicle) }
            archiveButton(for: row.vehicle, viewModel: viewModel)
        }
    }

    @ViewBuilder
    private func archiveButton(for vehicle: Vehicle, viewModel: VehicleListViewModel) -> some View {
        if scope == .active {
            Button("Archive", systemImage: "archivebox") {
                Task { await viewModel.setArchived(true, on: vehicle) }
            }
            .tint(.orange)
        } else {
            Button("Unarchive", systemImage: "arrow.uturn.backward") {
                Task { await viewModel.setArchived(false, on: vehicle) }
            }
            .tint(.blue)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(
                scope == .active ? "No vehicles yet" : "Nothing archived",
                systemImage: scope == .active ? "car" : "archivebox"
            )
        } description: {
            Text(
                scope == .active
                    ? "Add your car or motorcycle to start tracking fuel and services."
                    : "Vehicles you archive show up here."
            )
        } actions: {
            if scope == .active {
                Button("Add vehicle", systemImage: "plus") { sheet = .create }
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    NavigationStack {
        VehicleListView(scope: .active)
    }
    .environment(\.dependencies, .preview)
}
