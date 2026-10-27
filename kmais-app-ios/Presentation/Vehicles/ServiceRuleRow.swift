import SwiftUI

struct ServiceRuleRow: View {
    @Binding var rule: VehicleFormViewModel.RuleDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Service type", selection: $rule.kind) {
                ForEach(ServiceKind.allCases, id: \.self) { kind in
                    Text(kind.label).tag(kind)
                }
            }
            LabeledNumberField("Every", unit: "km", style: .kilometers, text: $rule.kilometerInterval)
            LabeledNumberField("Or every", unit: "months", style: .months, text: $rule.monthInterval)
            ValidationFooter(issues: rule.issues)
        }
        .padding(.vertical, 4)
    }
}
