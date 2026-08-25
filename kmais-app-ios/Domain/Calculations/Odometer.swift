import Foundation

/// Leitura de odômetro derivada do histórico.
enum Odometer {

    /// A leitura mais recente. `nil` com histórico vazio.
    ///
    /// "Mais recente" é por data, não o maior valor: um odômetro que retrocede
    /// é dado inconsistente, e devolver o máximo esconderia o problema em vez
    /// de deixar o valor errado à vista.
    static func current(_ samples: [OdometerSample]) -> Double? {
        samples.sortedChronologically().last?.odometer
    }

    /// Todas as leituras conhecidas de um veículo: o valor de cadastro, os
    /// abastecimentos e os serviços.
    ///
    /// Montar essa lista é parte do cálculo, não da apresentação — é o que
    /// impede cada tela de decidir sozinha o que conta como leitura.
    static func samples(
        vehicle: Vehicle,
        fuel: [FuelEntry],
        services: [ServiceEntry]
    ) -> [OdometerSample] {
        [OdometerSample(date: vehicle.createdAt, odometer: vehicle.initialOdometer)]
            + fuel.map { OdometerSample(date: $0.date, odometer: $0.odometer) }
            + services.map { OdometerSample(date: $0.date, odometer: $0.odometer) }
    }
}
