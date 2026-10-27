import SwiftUI

struct SymbolBadgeView: View {
    let systemName: String
    let tint: Color
    var size: CGFloat = 36

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.15), in: .rect(cornerRadius: size * 0.3))
            .accessibilityHidden(true)
    }
}
