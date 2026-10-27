import SwiftUI

struct ValidationFooter: View {
    let issues: [ValidationIssue]

    var body: some View {
        if !issues.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(issues) { issue in
                    Label {
                        Text(issue.message)
                    } icon: {
                        Image(systemName: issue.isBlocking ? "exclamationmark.triangle.fill" : "info.circle.fill")
                    }
                    .font(.footnote)
                    .foregroundStyle(issue.isBlocking ? .red : .orange)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
}
