import Foundation

/// Consumo entre tanques cheios.
enum Consumption {

    /// Todos os trechos calculáveis do histórico, em ordem cronológica.
    ///
    /// Um trecho é aberto e fechado apenas por `isFullTank == true`.
    /// Abastecimentos parciais no meio somam litros ao trecho corrente, mas não
    /// o abrem nem o fecham. Parciais anteriores ao primeiro tanque cheio são
    /// ignorados: não há trecho aberto para receber os litros.
    ///
    /// Registros com litros não positivos são ignorados por completo — não
    /// participam do acúmulo e não fecham um trecho. Trechos com distância ou
    /// litros não positivos não são produzidos. Em ambos os casos o motivo sai
    /// por `anomalies(in:)`; aqui só sobra o que é calculável.
    static func intervals(from records: [FuelEntry]) -> [ConsumptionInterval] {
        var intervals: [ConsumptionInterval] = []
        var open: FuelEntry?
        var litersSinceOpen = 0.0

        for record in records.sortedChronologically() where record.liters > 0 {
            guard let start = open else {
                if record.isFullTank { open = record }
                continue
            }

            litersSinceOpen += record.liters
            guard record.isFullTank else { continue }

            let interval = ConsumptionInterval(
                startDate: start.date,
                endDate: record.date,
                startOdometer: start.odometer,
                endOdometer: record.odometer,
                liters: litersSinceOpen
            )
            if interval.distance > 0 {
                intervals.append(interval)
            }

            open = record
            litersSinceOpen = 0
        }

        return intervals
    }

    /// O trecho fechado mais recente, ou `nil` se ainda não houve dois tanques
    /// cheios utilizáveis.
    static func latest(from records: [FuelEntry]) -> ConsumptionInterval? {
        intervals(from: records).last
    }

    /// Média ponderada em km/l: soma das distâncias dividida pela soma dos
    /// litros de todos os trechos.
    ///
    /// Ponderada, e não média das médias, para que um trecho longo pese mais
    /// que um curto.
    static func average(from records: [FuelEntry]) -> Double? {
        let intervals = intervals(from: records)
        guard !intervals.isEmpty else { return nil }

        let liters = intervals.reduce(0) { $0 + $1.liters }
        guard liters > 0 else { return nil }

        return intervals.reduce(0) { $0 + $1.distance } / liters
    }

    /// Registros que o cálculo não consegue usar, em ordem cronológica.
    ///
    /// As comparações de odômetro são sempre com o registro imediatamente
    /// anterior, não com o maior odômetro já visto: assim um único valor
    /// digitado errado marca uma linha, em vez de contaminar todas as
    /// seguintes.
    static func anomalies(in records: [FuelEntry]) -> [ConsumptionAnomaly] {
        var anomalies: [ConsumptionAnomaly] = []
        var previous: FuelEntry?

        for record in records.sortedChronologically() {
            defer { previous = record }

            if record.liters <= 0 {
                anomalies.append(ConsumptionAnomaly(record: record, kind: .nonPositiveLiters))
            }

            guard let previous else { continue }

            if record.odometer < previous.odometer {
                anomalies.append(
                    ConsumptionAnomaly(
                        record: record,
                        kind: .odometerWentBackwards(previous: previous.odometer)
                    )
                )
            } else if record.odometer == previous.odometer {
                let isDuplicate = record.date == previous.date
                    && record.liters == previous.liters
                    && record.pricePerLiter == previous.pricePerLiter
                anomalies.append(
                    ConsumptionAnomaly(
                        record: record,
                        kind: isDuplicate
                            ? .duplicate(of: previous.id)
                            : .odometerUnchanged(previous: previous.odometer)
                    )
                )
            }
        }

        return anomalies
    }
}
