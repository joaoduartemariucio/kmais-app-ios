import Foundation

nonisolated enum ServiceKind: String, Codable, CaseIterable, Sendable {
    case oilChange
    case oilFilter
    case airFilter
    case fuelFilter
    case sparkPlugs
    case brakes
    case tires
    case chain
    case coolant
    case inspection
    case other
}
