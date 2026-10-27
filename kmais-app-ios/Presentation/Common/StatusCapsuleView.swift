import SwiftUI

struct StatusCapsuleView: View {
    let level: MaintenanceStatus.Level

    var body: some View {
        Label {
            Text(level.label)
        } icon: {
            Image(systemName: level.symbolName)
        }
        .labelStyle(.titleAndIcon)
        .font(.caption.weight(.semibold))
        .foregroundStyle(level.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(level.color.opacity(0.15), in: .capsule)
    }
}
