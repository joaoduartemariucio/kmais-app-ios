import SwiftUI

/// Placeholder até as telas existirem.
///
/// Não usa `@Query`: com repositório no meio, quem lê são os ViewModels. A raiz
/// só carrega as dependências para baixo.
struct RootView: View {
    let dependencies: AppDependencies

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No vehicles yet",
                systemImage: "car",
                description: Text("Screens land in the next step.")
            )
            .navigationTitle("Kmais")
        }
    }
}
