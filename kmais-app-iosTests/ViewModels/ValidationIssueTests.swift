import Foundation
import Testing
@testable import kmais_app_ios

@MainActor
@Suite("Validation issues")
struct ValidationIssueTests {
    private let readings = [sample(0, 1_000), sample(20, 2_000)]

    @Test("a missing odometer is required")
    func missingOdometer() {
        #expect(ValidationIssue.odometer(nil, at: day(10), otherReadings: readings) == [.odometerRequired])
    }

    @Test("an odometer between its neighbors has no issue")
    func inOrder() {
        #expect(ValidationIssue.odometer(1_500, at: day(10), otherReadings: readings).isEmpty)
    }

    @Test("an odometer not above the previous reading warns")
    func notAfterPrevious() {
        let issues = ValidationIssue.odometer(1_000, at: day(10), otherReadings: readings)

        #expect(issues == [.odometerNotAfterPrevious(previous: 1_000)])
        #expect(!issues.blocksSaving)
    }

    @Test("an odometer not below the next reading warns")
    func notBeforeNext() {
        let issues = ValidationIssue.odometer(2_000, at: day(10), otherReadings: readings)

        #expect(issues == [.odometerNotBeforeNext(next: 2_000)])
        #expect(!issues.blocksSaving)
    }

    @Test("only the odometer order is a warning; everything else blocks saving")
    func blocking() {
        let warnings: [ValidationIssue] = [.odometerNotAfterPrevious(previous: 1), .odometerNotBeforeNext(next: 1)]
        let errors: [ValidationIssue] = [
            .nameRequired, .odometerRequired, .litersRequired, .litersNotPositive,
            .priceRequired, .priceNotPositive, .costNegative, .ruleWithoutInterval
        ]

        let warningsBlock = warnings.contains(where: \.isBlocking)
        let errorsBlock = errors.allSatisfy(\.isBlocking)

        #expect(!warningsBlock)
        #expect(errorsBlock)
        #expect((warnings + [.nameRequired]).blocksSaving)
    }

    @Test("every issue has a message")
    func messages() {
        let issues: [ValidationIssue] = [
            .nameRequired, .odometerRequired, .odometerNotAfterPrevious(previous: 1_000),
            .odometerNotBeforeNext(next: 2_000), .litersRequired, .litersNotPositive, .priceRequired,
            .priceNotPositive, .costNegative, .ruleWithoutInterval
        ]

        for issue in issues {
            #expect(!String(localized: issue.message).isEmpty, "\(issue)")
        }
    }
}
