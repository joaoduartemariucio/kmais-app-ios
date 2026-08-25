import Foundation

/// Fonte de "agora" e do calendário em uso.
///
/// Nenhum tipo do domínio ou de apresentação lê o relógio direto: com isso
/// qualquer comportamento dependente de tempo é testável sem esperar o tempo
/// passar.
protocol DateProvider: Sendable {
    var now: Date { get }
    var calendar: Calendar { get }
}
