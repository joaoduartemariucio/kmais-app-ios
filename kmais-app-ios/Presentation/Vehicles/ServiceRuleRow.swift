import SwiftUI

struct ServiceRuleRow: View {
    @Binding var rule: VehicleFormViewModel.RuleDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                SymbolBadgeView(systemName: rule.kind.symbolName, tint: .service, size: 32)
                Picker("Service type", selection: $rule.kind) {
                    ForEach(ServiceKind.allCases, id: \.self) { kind in
                        Label { Text(kind.label) } icon: { Image(systemName: kind.symbolName) }
                            .tag(kind)
                    }
                }
                .labelsHidden()
                .fixedSize()
                Spacer(minLength: 0)
            }
            LabeledNumberField("Every", unit: "km", style: .kilometers, text: $rule.kilometerInterval)
            LabeledNumberField("Or every", unit: "months", style: .months, text: $rule.monthInterval)
            ValidationFooter(issues: rule.issues)
        }
        .padding(.vertical, 4)
    }
}
