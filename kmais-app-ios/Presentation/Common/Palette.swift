import SwiftUI

extension Color {
    static let fuel = Color.teal
    static let service = Color.indigo
}

extension MaintenanceStatus.Level {
    var label: LocalizedStringResource {
        switch self {
        case .onTrack: "On track"
        case .dueSoon: "Due soon"
        case .overdue: "Overdue"
        }
    }

    var symbolName: String {
        switch self {
        case .onTrack: "checkmark.circle.fill"
        case .dueSoon: "clock.badge.exclamationmark.fill"
        case .overdue: "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .onTrack: .green
        case .dueSoon: .orange
        case .overdue: .red
        }
    }
}
