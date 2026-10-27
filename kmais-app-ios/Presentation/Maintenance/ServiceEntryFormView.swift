import SwiftUI

struct ServiceEntryFormView: View {
    let mode: ServiceEntryFormViewModel.Mode
    let lastOdometer: Double?
    let onSaved: () -> Void

    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ServiceEntryFormViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    form(for: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(isCreating ? "New service" : "Edit service")
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
                viewModel = ServiceEntryFormViewModel(
                    mode: mode,
                    repository: dependencies.serviceRepository,
                    dateProvider: dependencies.dateProvider,
                    lastOdometer: lastOdometer
                )
            }
        }
    }

    private var isCreating: Bool {
        if case .create = mode { true } else { false }
    }

    private func save(_ viewModel: ServiceEntryFormViewModel) async {
        await viewModel.save()
        if viewModel.state == .saved {
            onSaved()
            dismiss()
        }
    }

    @ViewBuilder
    private func form(for viewModel: ServiceEntryFormViewModel) -> some View {
        @Bindable var viewModel = viewModel

        Form {
            Section {
                Picker("Service type", selection: $viewModel.kind) {
                    ForEach(ServiceKind.allCases, id: \.self) { kind in
                        Text(kind.label).tag(kind)
                    }
                }
                DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                LabeledNumberField("Odometer", unit: "km", style: .kilometers, text: $viewModel.odometer)
                LabeledNumberField("Cost", style: .money, text: $viewModel.cost)
            }

            Section("Notes") {
                TextField("Notes", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(3...6)
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
    ServiceEntryFormView(
        mode: .create(vehicleID: PreviewData.car.id),
        lastOdometer: 42_000,
        onSaved: {}
    )
    .environment(\.dependencies, .preview)
}
