import Foundation

enum ValidationIssue: Hashable, Identifiable {
    case nameRequired
    case odometerRequired
    case odometerNotAfterPrevious(previous: Double)
    case odometerNotBeforeNext(next: Double)
    case litersRequired
    case litersNotPositive
    case priceRequired
    case priceNotPositive
    case costNegative
    case ruleWithoutInterval

    var id: Self { self }

    var message: LocalizedStringResource {
        switch self {
        case .nameRequired:
            "Give the vehicle a name."
        case .odometerRequired:
            "Enter the odometer reading."
        case .odometerNotAfterPrevious(let previous):
            "The odometer must be above the previous record (\(previous.formattedKilometers()))."
        case .odometerNotBeforeNext(let next):
            "The odometer must be below the next record (\(next.formattedKilometers()))."
        case .litersRequired:
            "Enter how many liters you filled."
        case .litersNotPositive:
            "Liters must be greater than zero."
        case .priceRequired:
            "Enter the price per liter."
        case .priceNotPositive:
            "Price must be greater than zero."
        case .costNegative:
            "Cost cannot be negative."
        case .ruleWithoutInterval:
            "A reminder needs a distance or a time interval."
        }
    }
}

extension ValidationIssue {
    static func odometer(
        _ odometer: Double?,
        at date: Date,
        otherReadings: [OdometerSample]
    ) -> [ValidationIssue] {
        guard let odometer else { return [.odometerRequired] }

        let neighbors = Odometer.neighbors(of: date, in: otherReadings)
        var issues: [ValidationIssue] = []
        if let previous = neighbors.previous, odometer <= previous {
            issues.append(.odometerNotAfterPrevious(previous: previous))
        }
        if let next = neighbors.next, odometer >= next {
            issues.append(.odometerNotBeforeNext(next: next))
        }
        return issues
    }
}
