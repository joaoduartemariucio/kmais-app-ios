import Foundation

enum FormState: Equatable {
    case editing
    case saving
    case saved
    case failed(message: String)

    var isSaving: Bool { self == .saving }
}
