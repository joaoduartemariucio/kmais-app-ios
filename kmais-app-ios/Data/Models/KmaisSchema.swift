import Foundation
import SwiftData

/// O schema do app e a criação do container.
enum KmaisSchema {
    static let schema = Schema([
        VehicleModel.self,
        FuelEntryModel.self,
        ServiceEntryModel.self,
        ServiceRuleModel.self
    ])

    /// - Parameter inMemory: usado por testes e previews.
    ///
    /// `cloudKitDatabase: .none` é explícito: com `.automatic` o SwiftData
    /// religaria o mirroring sozinho se um entitlement de iCloud reaparecesse
    /// no target.
    static func container(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
