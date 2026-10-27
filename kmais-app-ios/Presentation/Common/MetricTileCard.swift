import SwiftUI

struct MetricTileCard: View {
    let title: LocalizedStringResource
    let value: String?
    var caption: String?
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage).foregroundStyle(tint)
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)

            Text(value ?? String(localized: "Not enough data"))
                .font(value == nil ? .subheadline : .title3.weight(.semibold))
                .foregroundStyle(value == nil ? .secondary : .primary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}
