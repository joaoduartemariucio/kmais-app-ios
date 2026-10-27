import SwiftUI

struct VehicleDetailView: View {
    let vehicle: Vehicle

    @Environment(\.dependencies) private var dependencies
    @State private var viewModel: VehicleDetailViewModel?
    @State private var sheet: Sheet?

    private enum Sheet: Identifiable {
        case newFuel
        case newService
        case editFuel(FuelEntry)
        case editService(ServiceEntry)
        case editVehicle([ServiceRule])

        var id: String {
            switch self {
            case .newFuel: "newFuel"
            case .newService: "newService"
            case .editFuel(let entry): "fuel-\(entry.id)"
            case .editService(let entry): "service-\(entry.id)"
            case .editVehicle: "vehicle"
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
        .navigationTitle(vehicle.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Fuel-up", systemImage: "fuelpump") { sheet = .newFuel }
                    Button("Service", systemImage: "wrench.and.screwdriver") { sheet = .newService }
                } label: {
                    Label("Add record", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit vehicle", systemImage: "pencil") {
                    sheet = .editVehicle(viewModel?.rules ?? [])
                }
            }
        }
        .sheet(item: $sheet) { sheet in
            sheetContent(for: sheet)
        }
        .task {
            if viewModel == nil {
                viewModel = VehicleDetailViewModel(
                    vehicle: vehicle,
                    fuelEntryRepository: dependencies.fuelEntryRepository,
                    serviceRepository: dependencies.serviceRepository,
                    dateProvider: dependencies.dateProvider
                )
            }
            await viewModel?.load()
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: Sheet) -> some View {
        let reload: () -> Void = { Task { await viewModel?.load() } }

        switch sheet {
        case .newFuel:
            FuelEntryFormView(
                mode: .create(vehicleID: vehicle.id),
                otherReadings: viewModel?.odometerReadings() ?? [],
                onSaved: reload
            )
        case .editFuel(let entry):
            FuelEntryFormView(
                mode: .edit(entry),
                otherReadings: viewModel?.odometerReadings(excluding: .fuel(entry)) ?? [],
                onSaved: reload
            )
        case .newService:
            ServiceEntryFormView(
                mode: .create(vehicleID: vehicle.id),
                otherReadings: viewModel?.odometerReadings() ?? [],
                onSaved: reload
            )
        case .editService(let entry):
            ServiceEntryFormView(
                mode: .edit(entry),
                otherReadings: viewModel?.odometerReadings(excluding: .service(entry)) ?? [],
                onSaved: reload
            )
        case .editVehicle(let rules):
            VehicleFormView(mode: .edit(vehicle), existingRules: rules, onSaved: reload)
        }
    }

    @ViewBuilder
    private func content(for viewModel: VehicleDetailViewModel) -> some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .failed(let message):
            EmptyStateView(
                title: "Could not load this vehicle",
                systemImage: "exclamationmark.triangle",
                message: LocalizedStringKey(message)
            )
        case .loaded(let content):
            List {
                Section("Summary") {
                    VehicleSummaryCard(stats: content.stats)
                }

                if content.sections.isEmpty {
                    Section {
                        EmptyStateView(
                            title: "No history yet",
                            systemImage: "list.bullet.rectangle",
                            message: "Log a fuel-up or a service to see it here."
                        )
                    }
                } else {
                    ForEach(content.sections) { section in
                        Section(section.month.formattedMonthAndYear) {
                            ForEach(section.items) { item in
                                row(for: item, viewModel: viewModel)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func row(
        for item: VehicleTimeline.Item,
        viewModel: VehicleDetailViewModel
    ) -> some View {
        Group {
            switch item {
            case .fuel(let entry):
                Button { sheet = .editFuel(entry) } label: { FuelEntryRow(entry: entry) }
            case .service(let entry):
                Button { sheet = .editService(entry) } label: { ServiceEntryRow(entry: entry) }
            }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button("Delete", systemImage: "trash", role: .destructive) {
                Task { await viewModel.delete(item) }
            }
        }
    }
}

#Preview {
    NavigationStack {
        VehicleDetailView(vehicle: PreviewData.car)
    }
    .environment(\.dependencies, .preview)
}
