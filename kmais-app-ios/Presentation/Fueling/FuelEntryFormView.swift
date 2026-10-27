import SwiftUI

struct FuelEntryFormView: View {
    let mode: FuelEntryFormViewModel.Mode
    let otherReadings: [OdometerSample]
    var suggestedPrice: Decimal?
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
                    otherReadings: otherReadings,
                    suggestedPrice: suggestedPrice
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
                totalHeader(viewModel.totalCost)
            }

            Section {
                LabeledNumberField("Liters", unit: "L", style: .liters, text: $viewModel.liters)
                LabeledNumberField("Price per liter", style: .fuelPrice, text: $viewModel.pricePerLiter)
                Toggle(isOn: $viewModel.isFullTank) {
                    Label("Full tank", systemImage: "fuelpump.fill")
                }
            } header: {
                Text("Fuel")
            } footer: {
                if viewModel.isUsingSuggestedPrice {
                    Text("Price filled in from your last fuel-up.")
                }
            }

            Section {
                DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                LabeledNumberField("Odometer", unit: "km", style: .kilometers, text: $viewModel.odometer)
            } header: {
                Text("When")
            } footer: {
                OdometerHintView(
                    previous: viewModel.previousReading,
                    distance: viewModel.distanceSincePrevious
                )
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

    private func totalHeader(_ total: Decimal?) -> some View {
        VStack(spacing: 4) {
            Text("Total")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(total?.formattedCurrency ?? "—")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(total == nil ? .secondary : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .animation(.snappy, value: total)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    FuelEntryFormView(
        mode: .create(vehicleID: PreviewData.car.id),
        otherReadings: [OdometerSample(date: .now.addingTimeInterval(-7 * 86_400), odometer: 42_000)],
        onSaved: {}
    )
    .environment(\.dependencies, .preview)
}
