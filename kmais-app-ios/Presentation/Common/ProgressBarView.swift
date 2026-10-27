import SwiftUI

struct ProgressBarView: View {
    let value: Double
    let tint: Color

    var body: some View {
        Capsule()
            .fill(.fill.tertiary)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(tint.gradient)
                        .frame(width: max(6, proxy.size.width * min(1, max(0, value))))
                }
            }
            .frame(height: 6)
            .accessibilityElement()
            .accessibilityValue(Text(value, format: .percent.precision(.fractionLength(0))))
    }
}
