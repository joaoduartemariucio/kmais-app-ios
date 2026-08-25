import Foundation

/// O relógio de verdade.
struct SystemDateProvider: DateProvider {
    var now: Date { .now }
    var calendar: Calendar { .current }
}
