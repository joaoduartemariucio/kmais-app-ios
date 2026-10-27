import Testing
import UIKit
@testable import kmais_app_ios

@MainActor
@Suite("SF Symbols")
struct SymbolNameTests {
    @Test("every service kind uses a symbol that exists", arguments: ServiceKind.allCases)
    func serviceKind(_ kind: ServiceKind) {
        #expect(UIImage(systemName: kind.symbolName) != nil)
    }

    @Test("every vehicle kind and status uses a symbol that exists")
    func vehicleKindsAndStatuses() {
        let names = VehicleKind.allCases.map(\.symbolName)
            + [MaintenanceStatus.Level.onTrack, .dueSoon, .overdue].map(\.symbolName)
        for name in names {
            #expect(UIImage(systemName: name) != nil, "\(name)")
        }
    }
}
