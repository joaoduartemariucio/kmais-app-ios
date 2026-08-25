import Foundation

/// Por que um formulário ainda não pode ser salvo.
///
/// Um enum e não uma `String` para que a razão seja testável e a mensagem
/// localizável num lugar só.
enum ValidationIssue: Hashable, Identifiable {
    case nameRequired
    case odometerRequired
    case odometerNotAfterLast(last: Double)
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
        case .odometerNotAfterLast(let last):
            "The odometer must be above the last record (\(last.formattedKilometers()))."
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
