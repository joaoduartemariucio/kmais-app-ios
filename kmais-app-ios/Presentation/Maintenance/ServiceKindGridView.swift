import SwiftUI

struct ServiceKindGridView: View {
    @Binding var selection: ServiceKind

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(ServiceKind.allCases, id: \.self) { kind in
                let isSelected = kind == selection
                Button {
                    selection = kind
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: kind.symbolName)
                            .font(.title3)
                        Text(kind.label)
                            .font(.caption.weight(.medium))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .background(
                        isSelected ? AnyShapeStyle(Color.service) : AnyShapeStyle(.fill.tertiary),
                        in: .rect(cornerRadius: 12)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}
