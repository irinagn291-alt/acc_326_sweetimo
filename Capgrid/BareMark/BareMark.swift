import Foundation

/// Cap on Open writes a BareMark. It is a refusal: no CapMark, no total change.
/// The mark stays in the log so the refused stamp is visible after relaunch.
struct BareMark: Hashable, Codable, Sendable, Identifiable {
    var id: UUID
    var kind: StatKind
    var at: Date
}

/// Result of `Sheet.cap`. Only `.stamped` is a successful commit.
enum CapOutcome: Hashable, Sendable {
    case stamped(CapMark)
    case refused(BareMark)
}
