import Foundation

extension VehicleKind {
    var label: LocalizedStringResource {
        switch self {
        case .car: "Car"
        case .motorcycle: "Motorcycle"
        }
    }

    var symbolName: String {
        switch self {
        case .car: "car.fill"
        case .motorcycle: "motorcycle.fill"
        }
    }
}
