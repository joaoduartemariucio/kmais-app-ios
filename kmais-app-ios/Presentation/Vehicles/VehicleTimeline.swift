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

        var cost: Decimal {
            switch self {
            case let .fuel(entry): entry.totalCost
            case let .service(entry): entry.cost
            }
        }

        func matches(_ filter: Filter) -> Bool {
            switch (filter, self) {
            case (.all, _), (.fuel, .fuel), (.service, .service): true
            case (.fuel, .service), (.service, .fuel): false
            }
        }
    }

    enum Filter: CaseIterable, Hashable {
        case all
        case fuel
        case service

        var label: LocalizedStringResource {
            switch self {
            case .all: "All"
            case .fuel: "Fuel"
            case .service: "Services"
            }
        }
    }

    struct MonthSection: Identifiable {
        let id: Date
        let items: [Item]

        var month: Date { id }
        var total: Decimal { items.reduce(.zero) { $0 + $1.cost } }

        func filtered(by filter: Filter) -> MonthSection? {
            let kept = items.filter { $0.matches(filter) }
            return kept.isEmpty ? nil : MonthSection(id: id, items: kept)
        }
    }

    struct MonthSpending: Identifiable {
        let month: Date
        let fuel: Decimal
        let service: Decimal

        var id: Date { month }
        var total: Decimal { fuel + service }
    }

    static func sections(
        fuel: [FuelEntry],
        services: [ServiceEntry],
        calendar: Calendar
    ) -> [MonthSection] {
        let items = fuel.map(Item.fuel) + services.map(Item.service)

        let grouped = Dictionary(grouping: items) { item in
            monthStart(of: item.date, calendar: calendar)
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

    static func spending(
        _ sections: [MonthSection],
        months: Int,
        endingAt now: Date,
        calendar: Calendar
    ) -> [MonthSpending] {
        let byMonth = Dictionary(uniqueKeysWithValues: sections.map { ($0.month, $0.items) })
        let current = monthStart(of: now, calendar: calendar)

        return (0..<max(0, months)).reversed().compactMap { offset in
            guard let month = calendar.date(byAdding: .month, value: -offset, to: current) else { return nil }
            let items = byMonth[month] ?? []
            return MonthSpending(
                month: month,
                fuel: items.filter { $0.matches(.fuel) }.reduce(.zero) { $0 + $1.cost },
                service: items.filter { $0.matches(.service) }.reduce(.zero) { $0 + $1.cost }
            )
        }
    }

    private static func monthStart(of date: Date, calendar: Calendar) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }
}
