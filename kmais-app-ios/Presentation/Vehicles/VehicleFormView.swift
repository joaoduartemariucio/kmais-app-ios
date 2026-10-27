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
                TextField("Name", text: $viewModel.name)
                Picker("Vehicle type", selection: $viewModel.kind) {
                    ForEach(VehicleKind.allCases, id: \.self) { kind in
                        Text(kind.label).tag(kind)
                    }
                }
                TextField("Plate", text: $viewModel.plate)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                LabeledNumberField("Initial odometer", unit: "km", style: .kilometers, text: $viewModel.initialOdometer)
                LabeledNumberField("Tank capacity", unit: "L", style: .liters, text: $viewModel.tankCapacity)
            }

            Section("Service reminders") {
                if viewModel.rules.isEmpty {
                    Text("No reminders yet").foregroundStyle(.secondary)
                } else {
                    ForEach($viewModel.rules) { $rule in
                        ServiceRuleRow(rule: $rule)
                    }
                    .onDelete { viewModel.removeRules(at: $0) }
                }

                Button("Add reminder", systemImage: "plus") { viewModel.addRule() }
            }

            if case .failed(let message) = viewModel.state {
                Section {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }

            Section {
                ValidationFooter(issues: viewModel.issues)
            }
        }
    }
}

#Preview {
    VehicleFormView(mode: .create, onSaved: {})
        .environment(\.dependencies, .preview)
}
