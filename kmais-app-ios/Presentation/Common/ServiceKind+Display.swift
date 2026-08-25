import Foundation

extension ServiceKind {
    var label: LocalizedStringResource {
        switch self {
        case .oilChange: "Oil change"
        case .oilFilter: "Oil filter"
        case .airFilter: "Air filter"
        case .fuelFilter: "Fuel filter"
        case .sparkPlugs: "Spark plugs"
        case .brakes: "Brakes"
        case .tires: "Tires"
        case .chain: "Chain"
        case .coolant: "Coolant"
        case .inspection: "Inspection"
        case .other: "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .oilChange, .oilFilter: "oilcan.fill"
        case .airFilter, .fuelFilter: "air.purifier.fill"
        case .sparkPlugs: "bolt.fill"
        case .brakes: "brake.signal"
        case .tires: "tire"
        case .chain: "link"
        case .coolant: "thermometer.medium"
        case .inspection: "checklist"
        case .other: "wrench.and.screwdriver.fill"
        }
    }
}
