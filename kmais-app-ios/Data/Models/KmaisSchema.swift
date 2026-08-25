import Foundation
import SwiftData

enum KmaisSchema {
    static let schema = Schema([
        VehicleModel.self,
        FuelEntryModel.self,
        ServiceEntryModel.self,
        ServiceRuleModel.self
    ])

    static func container(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
