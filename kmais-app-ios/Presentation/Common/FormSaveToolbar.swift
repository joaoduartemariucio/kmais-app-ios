import SwiftUI

struct FormSaveToolbar: ToolbarContent {
    let state: FormState
    let canSave: Bool
    let save: () -> Void
    let cancel: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", action: cancel)
        }
        ToolbarItem(placement: .confirmationAction) {
            if state.isSaving {
                ProgressView()
            } else {
                Button("Save", action: save).disabled(!canSave)
            }
        }
    }
}
