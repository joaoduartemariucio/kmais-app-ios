import Foundation

nonisolated struct ServiceDue: Hashable, Sendable {
    let rule: ServiceRule
    let forecast: MaintenanceForecast
}
