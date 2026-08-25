import Foundation

protocol DateProvider: Sendable {
    var now: Date { get }
    var calendar: Calendar { get }
}
