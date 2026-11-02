import Foundation

/// Player in the box-score lexicon. A Jersey is the number seated on the pin rail.
/// Caps never name a person; they name this number and which bench it plays for.
struct Jersey: Hashable, Codable, Sendable, Identifiable {
    var number: Int
    var bench: Bench

    var id: String { "\(bench.rawValue)#\(number)" }

    /// Wearable sideline numbers. 0 and 100+ are refused before a TagMark is written.
    var isWearable: Bool { (1...99).contains(number) }

    init(number: Int, bench: Bench = .home) {
        self.number = number
        self.bench = bench
    }
}

/// Which totals strip a stamped cap folds into.
enum Bench: String, Codable, Sendable, Hashable {
    case home
    case away
}
