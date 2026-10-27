import SwiftUI

struct FuelEntryFormView: View {
    let mode: FuelEntryFormViewModel.Mode
    let lastOdometer: Double?
    let onSaved: () -> Void

    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: FuelEntryFormViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    form(for: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(isCreating ? "New fuel-up" : "Edit fuel-up")
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
                viewModel = FuelEntryFormViewModel(
                    mode: mode,
                    repository: dependencies.fuelEntryRepository,
                    dateProvider: dependencies.dateProvider,
                    lastOdometer: lastOdometer
                )
            }
        }
    }

    private var isCreating: Bool {
        if case .create = mode { true } else { false }
    }

    private func save(_ viewModel: FuelEntryFormViewModel) async {
        await viewModel.save()
        if viewModel.state == .saved {
            onSaved()
            dismiss()
        }
    }

    @ViewBuilder
    private func form(for viewModel: FuelEntryFormViewModel) -> some View {
        @Bindable var viewModel = viewModel

        Form {
            Section {
                DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                LabeledNumberField("Odometer", unit: "km", style: .kilometers, text: $viewModel.odometer)
                LabeledNumberField("Liters", unit: "L", style: .liters, text: $viewModel.liters)
                LabeledNumberField("Price per liter", style: .fuelPrice, text: $viewModel.pricePerLiter)
                Toggle("Full tank", isOn: $viewModel.isFullTank)
            }

            Section {
                LabeledContent("Total") {
                    Text(viewModel.totalCost?.formattedCurrency ?? String(localized: "Not enough data"))
                        .foregroundStyle(viewModel.totalCost == nil ? .secondary : .primary)
                }
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
    FuelEntryFormView(
        mode: .create(vehicleID: PreviewData.car.id),
        lastOdometer: 42_000,
        onSaved: {}
    )
    .environment(\.dependencies, .preview)
}
