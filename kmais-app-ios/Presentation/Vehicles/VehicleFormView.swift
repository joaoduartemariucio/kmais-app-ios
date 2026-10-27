import SwiftUI

struct VehicleFormView: View {
    let mode: VehicleFormViewModel.Mode
    var existingRules: [ServiceRule] = []
    let onSaved: () -> Void

    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: VehicleFormViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    form(for: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(isCreating ? "New vehicle" : "Edit vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let viewModel {
                    FormSaveToolbar(
                        state: viewModel.state,
                        canSave: viewModel.canSave,
                        save: { Task { await save(viewModel) } },
                        cancel: { dismiss() }
                    )
                }
            }
        }
        .task {
            if viewModel == nil {
                viewModel = VehicleFormViewModel(
                    mode: mode,
                    existingRules: existingRules,
                    vehicleRepository: dependencies.vehicleRepository,
                    serviceRepository: dependencies.serviceRepository,
                    dateProvider: dependencies.dateProvider
                )
            }
        }
    }

    private var isCreating: Bool {
        if case .create = mode { true } else { false }
    }

    private func save(_ viewModel: VehicleFormViewModel) async {
        await viewModel.save()
        if viewModel.state == .saved {
            onSaved()
            dismiss()
        }
    }

    @ViewBuilder
    private func form(for viewModel: VehicleFormViewModel) -> some View {
        @Bindable var viewModel = viewModel

        Form {
            Section {
                Picker("Vehicle type", selection: $viewModel.kind) {
                    ForEach(VehicleKind.allCases, id: \.self) { kind in
                        Label { Text(kind.label) } icon: { Image(systemName: kind.symbolName) }
                            .tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Identification") {
                TextField("Name", text: $viewModel.name, prompt: Text("e.g. Civic, CB 500"))
                TextField("Plate", text: $viewModel.plate, prompt: Text("ABC1D23"))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            }

            Section("Specs") {
                LabeledNumberField("Initial odometer", unit: "km", style: .kilometers, text: $viewModel.initialOdometer)
                LabeledNumberField("Tank capacity", unit: "L", style: .liters, text: $viewModel.tankCapacity)
            }

            Section {
                ForEach($viewModel.rules) { $rule in
                    ServiceRuleRow(rule: $rule)
                }
                .onDelete { viewModel.removeRules(at: $0) }

                Button("Add reminder", systemImage: "plus.circle.fill") { viewModel.addRule() }
            } header: {
                Text("Service reminders")
            } footer: {
                Text("You are reminded at whichever comes first: the distance or the time.")
            }

            if case let .failed(message) = viewModel.state {
                Section {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }

            if !viewModel.issues.isEmpty {
                Section {
                    ValidationFooter(issues: viewModel.issues)
                }
            }
        }
        .dismissesKeyboard()
    }
}

#Preview {
    VehicleFormView(mode: .create, onSaved: {})
        .environment(\.dependencies, .preview)
}
