import Foundation

/// Onde um formulário está no ciclo de salvamento.
///
/// Enum explícito para que a falha tenha que ser tratada: não há caminho em que
/// um erro de escrita simplesmente desapareça.
enum FormState: Equatable {
    case editing
    case saving
    case saved
    case failed(message: String)

    var isSaving: Bool { self == .saving }
}
