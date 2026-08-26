import SwiftUI

struct RootView: View {
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            VehicleListView(scope: .active)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .vehicleDetail(let vehicle):
                        VehicleDetailView(vehicle: vehicle)
                    case .archivedVehicles:
                        VehicleListView(scope: .archived)
                    }
                }
        }
    }
}

#Preview {
    RootView()
        .environment(\.dependencies, .preview)
}
