import SwiftUI

struct LabeledNumberField: View {
    let title: LocalizedStringKey
    let unit: LocalizedStringKey?
    let style: NumberInput.Style
    @Binding var text: String

    init(
        _ title: LocalizedStringKey,
        unit: LocalizedStringKey? = nil,
        style: NumberInput.Style,
        text: Binding<String>
    ) {
        self.title = title
        self.unit = unit
        self.style = style
        _text = text
    }

    var body: some View {
        LabeledContent {
            HStack {
                TextField(title, text: $text)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .onChange(of: text) { previous, current in
                        let masked = NumberInput.masked(current, previous: previous, style: style)
                        if masked != current { text = masked }
                    }
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
