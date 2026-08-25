import Foundation

/// Previsão de vencimento de revisões.
enum Maintenance {

    /// Duração média de um mês no calendário gregoriano.
    ///
    /// A projeção soma dias, não meses: uma média de km/mês combinada com
    /// "mês = 30 dias" acumula quase uma semana de erro por ano. O valor
    /// exposto em km/mês é derivado daqui só para leitura humana.
    static let averageDaysPerMonth = 365.25 / 12

    /// Ritmo de uso em km/dia, do primeiro ao último ponto do histórico.
    ///
    /// `nil` quando há menos de dois pontos, quando eles cobrem menos de um dia
    /// ou quando o odômetro não avançou.
    static func averageKilometersPerDay(_ samples: [OdometerSample]) -> Double? {
        let sorted = samples.sortedChronologically()
        guard let first = sorted.first, let last = sorted.last else { return nil }

        let days = last.date.timeIntervalSince(first.date) / 86_400
        let kilometers = last.odometer - first.odometer
        guard days > 0, kilometers > 0 else { return nil }

        return kilometers / days
    }

    /// Ritmo de uso em km/mês. Mesmas condições de ausência de
    /// `averageKilometersPerDay`.
    static func averageKilometersPerMonth(_ samples: [OdometerSample]) -> Double? {
        averageKilometersPerDay(samples).map { $0 * averageDaysPerMonth }
    }

    /// Estima quando a regra vence, contada a partir do último serviço.
    ///
    /// O ponto mais recente de `history` faz o papel de "agora": a função não
    /// lê o relógio, então o mesmo histórico sempre produz a mesma previsão.
    /// Se o histórico estiver defasado, acrescente uma leitura atual.
    ///
    /// Retorna `nil` quando não sobra nenhum critério: regra sem intervalo
    /// nenhum, ou regra só por km sem histórico suficiente para projetar.
    /// Nesse último caso `dueOdometer` até existiria, mas não há data — e o
    /// tipo promete uma.
    static func forecast(
        rule: ServiceRule,
        lastServiceDate: Date,
        lastServiceOdometer: Double,
        history: [OdometerSample],
        calendar: Calendar = .current
    ) -> MaintenanceForecast? {
        let kilometersPerDay = averageKilometersPerDay(history)
        let kilometersPerMonth = kilometersPerDay.map { $0 * averageDaysPerMonth }

        var dueOdometer: Double?
        var dateByDistance: Date?

        if let interval = rule.kilometerInterval, interval > 0 {
            let due = lastServiceOdometer + interval
            dueOdometer = due

            if let kilometersPerDay, let current = history.sortedChronologically().last {
                let days = (due - current.odometer) / kilometersPerDay
                // Um ritmo muito baixo projeta datas absurdas; acima de um
                // século a previsão não diz nada útil e ainda arrisca estourar
                // o Int na conversão.
                if days.isFinite, abs(days) < 36_525 {
                    dateByDistance = calendar.date(
                        byAdding: .day,
                        value: Int(days.rounded()),
                        to: current.date
                    )
                }
            }
        }

        var dateByCalendar: Date?
        if let months = rule.monthInterval, months > 0 {
            dateByCalendar = calendar.date(byAdding: .month, value: months, to: lastServiceDate)
        }

        let dueDate: Date
        let trigger: MaintenanceForecast.Trigger
        switch (dateByDistance, dateByCalendar) {
        case let (byDistance?, byCalendar?):
            dueDate = min(byDistance, byCalendar)
            trigger = byDistance <= byCalendar ? .distance : .calendar
        case let (byDistance?, nil):
            dueDate = byDistance
            trigger = .distance
        case let (nil, byCalendar?):
            dueDate = byCalendar
            trigger = .calendar
        case (nil, nil):
            return nil
        }

        return MaintenanceForecast(
            dueDate: dueDate,
            trigger: trigger,
            dueOdometer: dueOdometer,
            averageKilometersPerMonth: kilometersPerMonth
        )
    }
}
