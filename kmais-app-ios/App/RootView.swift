import SwiftUI

struct RootView: View {
    @Environment(\.dependencies) private var dependencies

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No vehicles yet",
                systemImage: "car",
                description: Text(
                    dependencies.isUsingFallbackStore
                        ? "Running on a temporary store — changes will not be saved."
                        : "Screens land in the next step."
                )
            )
            .navigationTitle("Kmais")
        }
    }
}

#Preview {
    RootView()
        .environment(\.dependencies, .inMemory())
}
