import SwiftUI

struct ServiceEntryFormView: View {
    let mode: ServiceEntryFormViewModel.Mode
    let otherReadings: [OdometerSample]
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
                    otherReadings: otherReadings
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
            Section("Service type") {
                ServiceKindGridView(selection: $viewModel.kind)
                    .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
            }

            Section {
                DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                LabeledNumberField("Odometer", unit: "km", style: .kilometers, text: $viewModel.odometer)
                LabeledNumberField("Cost", style: .money, text: $viewModel.cost)
            } footer: {
                OdometerHintView(previous: viewModel.previousReading)
            }

            Section("Notes") {
                TextField("Parts, shop, warranty…", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(3...6)
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
    ServiceEntryFormView(
        mode: .create(vehicleID: PreviewData.car.id),
        otherReadings: [OdometerSample(date: .now.addingTimeInterval(-7 * 86_400), odometer: 42_000)],
        onSaved: {}
    )
    .environment(\.dependencies, .preview)
}
