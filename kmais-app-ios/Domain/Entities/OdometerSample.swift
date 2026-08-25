import Foundation

/// Uma leitura de odômetro numa data.
///
/// O cálculo não distingue de onde veio a leitura: abastecimento, serviço ou
/// cadastro do veículo. Quem monta a lista é que decide.
struct OdometerSample: Hashable, Sendable, Chronological {
    var date: Date
    var odometer: Double

    init(date: Date, odometer: Double) {
        self.date = date
        self.odometer = odometer
    }
}
