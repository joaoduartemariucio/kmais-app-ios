import Foundation

/// O histórico do veículo: abastecimentos e serviços na mesma linha do tempo,
/// agrupados por mês, do mais recente para o mais antigo.
///
/// É agrupamento de apresentação, não cálculo: nenhuma métrica sai daqui.
enum VehicleTimeline {

    enum Item: Identifiable {
        case fuel(FuelEntry)
        case service(ServiceEntry)

        var id: UUID {
            switch self {
            case .fuel(let entry): entry.id
            case .service(let entry): entry.id
            }
        }

        var date: Date {
            switch self {
            case .fuel(let entry): entry.date
            case .service(let entry): entry.date
            }
        }

        var odometer: Double {
            switch self {
            case .fuel(let entry): entry.odometer
            case .service(let entry): entry.odometer
            }
        }
    }

    struct MonthSection: Identifiable {
        /// Primeiro instante do mês, que serve de identidade e de título.
        let id: Date
        let items: [Item]

        var month: Date { id }
    }

    static func sections(
        fuel: [FuelEntry],
        services: [ServiceEntry],
        calendar: Calendar
    ) -> [MonthSection] {
        let items = fuel.map(Item.fuel) + services.map(Item.service)

        let grouped = Dictionary(grouping: items) { item in
            calendar.date(from: calendar.dateComponents([.year, .month], from: item.date)) ?? item.date
        }

        return grouped
            .map { month, items in
                MonthSection(
                    id: month,
                    // Empate de data resolve pelo odômetro maior: dentro do
                    // mesmo dia, quem tem odômetro mais alto veio depois.
                    items: items.sorted {
                        $0.date == $1.date ? $0.odometer > $1.odometer : $0.date > $1.date
                    }
                )
            }
            .sorted { $0.month > $1.month }
    }
}
