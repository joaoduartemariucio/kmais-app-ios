import SwiftUI

struct OdometerHintView: View {
    let previous: Double?
    var distance: Double?

    var body: some View {
        if let previous {
            HStack(spacing: 4) {
                Image(systemName: "gauge.with.needle")
                Text("Last reading: \(previous.formattedKilometers())")
                if let distance {
                    Text(verbatim: "· +\(distance.formattedKilometers())")
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                }
            }
            .monospacedDigit()
        }
    }
}
