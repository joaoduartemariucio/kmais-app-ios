import Foundation

enum VehicleTimeline {
    enum Item: Identifiable {
        case fuel(FuelEntry)
        case service(ServiceEntry)

        var id: UUID {
            switch self {
            case let .fuel(entry): entry.id
            case let .service(entry): entry.id
            }
        }

        var date: Date {
            switch self {
            case let .fuel(entry): entry.date
            case let .service(entry): entry.date
            }
        }

        var odometer: Double {
            switch self {
            case let .fuel(entry): entry.odometer
            case let .service(entry): entry.odometer
            }
        }
    }

    struct MonthSection: Identifiable {
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
                    items: items.sorted {
                        $0.date == $1.date ? $0.odometer > $1.odometer : $0.date > $1.date
                    }
                )
            }
            .sorted { $0.month > $1.month }
    }
}
