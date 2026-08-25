import Foundation

/// Tipos de serviço reconhecidos pelo app.
///
/// Fechado de propósito: as regras de revisão precisam casar serviço com regra,
/// e tipo livre digitado pelo usuário não casa de forma confiável. Serviço fora
/// da lista entra como `.other` com descrição em `notes`.
enum ServiceKind: String, Codable, CaseIterable, Sendable {
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
