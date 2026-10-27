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
            case let .editFuel(entry): "fuel-\(entry.id)"
            case let .editService(entry): "service-\(entry.id)"
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
                Button("Edit vehicle", systemImage: "pencil") {
                    sheet = .editVehicle(viewModel?.rules ?? [])
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button { sheet = .newFuel } label: {
                    Label("Fuel-up", systemImage: "fuelpump.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(.fuel)
                Button { sheet = .newService } label: {
                    Label("Service", systemImage: "wrench.and.screwdriver.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(.service)
            }
            .font(.headline)
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom, 8)
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
                    dateProvider: dependencies.dateProvider,
                    reminders: dependencies.reminderSync
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
                suggestedPrice: viewModel?.lastPricePerLiter,
                onSaved: reload
            )
        case let .editFuel(entry):
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
        case let .editService(entry):
            ServiceEntryFormView(
                mode: .edit(entry),
                otherReadings: viewModel?.odometerReadings(excluding: .service(entry)) ?? [],
                onSaved: reload
            )
        case let .editVehicle(rules):
            VehicleFormView(mode: .edit(vehicle), existingRules: rules, onSaved: reload)
        }
    }

    @ViewBuilder
    private func content(for viewModel: VehicleDetailViewModel) -> some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case let .failed(message):
            EmptyStateView(
                title: "Could not load this vehicle",
                systemImage: "exclamationmark.triangle",
                message: LocalizedStringKey(message)
            )
        case let .loaded(content):
            loaded(content, viewModel: viewModel)
        }
    }

    private func loaded(_ content: VehicleDetailViewModel.Content, viewModel: VehicleDetailViewModel) -> some View {
        List {
            dashboard(content)
            history(content, viewModel: viewModel)
        }
        .listSectionSpacing(.compact)
        .refreshable { await viewModel.load() }
        .animation(.default, value: viewModel.filter)
    }

    @ViewBuilder
    private func dashboard(_ content: VehicleDetailViewModel.Content) -> some View {
        Section {
            VehicleHeroCard(vehicle: vehicle, stats: content.stats)
        }

        Section {
            VehicleSummaryCard(stats: content.stats)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }

        Section("Maintenance") {
            if content.stats.dues.isEmpty {
                Button {
                    sheet = .editVehicle(content.rules)
                } label: {
                    Label("Set up service reminders", systemImage: "bell.badge")
                }
            } else {
                ForEach(content.stats.dues) { item in
                    ServiceDueRow(item: item)
                }
            }
        }

        if content.stats.consumptionHistory.count >= 2 {
            Section {
                ConsumptionChartCard(
                    intervals: content.stats.consumptionHistory,
                    average: content.stats.averageConsumption
                )
            }
        }

        if content.spending.contains(where: { $0.total > 0 }) {
            Section {
                SpendingChartCard(months: content.spending)
            }
        }
    }

    @ViewBuilder
    private func history(_ content: VehicleDetailViewModel.Content, viewModel: VehicleDetailViewModel) -> some View {
        @Bindable var viewModel = viewModel

        if viewModel.hasHistory {
            Section {
                Picker("Show", selection: $viewModel.filter) {
                    ForEach(VehicleTimeline.Filter.allCases, id: \.self) { filter in
                        Text(filter.label).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } header: {
                Text("History")
            }

            ForEach(viewModel.visibleSections) { section in
                Section {
                    ForEach(section.items) { item in
                        row(for: item, stats: content.stats, viewModel: viewModel)
                    }
                } header: {
                    HStack {
                        Text(section.month.formattedMonthAndYear)
                        Spacer()
                        Text(section.total.formattedCurrency).monospacedDigit()
                    }
                }
            }
        } else {
            Section {
                EmptyStateView(
                    title: "No history yet",
                    systemImage: "list.bullet.rectangle",
                    message: "Log a fuel-up or a service to see it here."
                )
            }
        }
    }

    private func row(
        for item: VehicleTimeline.Item,
        stats: VehicleStats,
        viewModel: VehicleDetailViewModel
    ) -> some View {
        Group {
            switch item {
            case let .fuel(entry):
                Button { sheet = .editFuel(entry) } label: {
                    FuelEntryRow(entry: entry, consumption: stats.consumptionByEntry[entry.id])
                }
            case let .service(entry):
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
