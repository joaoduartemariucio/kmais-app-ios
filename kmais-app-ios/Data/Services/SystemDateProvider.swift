import Foundation

struct SystemDateProvider: DateProvider {
    var now: Date { .now }
    var calendar: Calendar { .current }
}
