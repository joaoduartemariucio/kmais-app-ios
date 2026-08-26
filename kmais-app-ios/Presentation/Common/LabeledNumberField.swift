import SwiftUI

struct LabeledNumberField: View {
    let title: LocalizedStringKey
    let unit: LocalizedStringKey?
    @Binding var text: String

    init(_ title: LocalizedStringKey, unit: LocalizedStringKey? = nil, text: Binding<String>) {
        self.title = title
        self.unit = unit
        self._text = text
    }

    var body: some View {
        LabeledContent {
            HStack {
                TextField(title, text: $text)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                if let unit {
                    Text(unit).foregroundStyle(.secondary)
                }
            }
        } label: {
            Text(title)
        }
        .accessibilityLabel(Text(title))
    }
}
