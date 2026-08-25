import Foundation

/// Um registro posicionado na linha do tempo do veículo.
///
/// Existe para que a ordenação canônica — data e, em empate, odômetro — tenha
/// uma implementação só, usada por consumo, custo e previsão.
protocol Chronological {
    var date: Date { get }
    var odometer: Double { get }
}

extension Array where Element: Chronological {
    /// Ordena por data e, em caso de empate, por odômetro crescente.
    ///
    /// Não corrige dados inconsistentes: um odômetro que retrocede continua
    /// retrocedendo depois da ordenação, e é isso que permite detectá-lo.
    func sortedChronologically() -> [Element] {
        sorted { lhs, rhs in
            lhs.date == rhs.date ? lhs.odometer < rhs.odometer : lhs.date < rhs.date
        }
    }
}
