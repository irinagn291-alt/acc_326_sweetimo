import Foundation

/// Peel drops the last CapMark on a Live sheet by appending this mark.
/// The CapMark stays in the log; the fold skips it. Peel after Seal is refused.
struct PeelMark: Hashable, Codable, Sendable, Identifiable {
    var id: UUID
    var droppedCapID: UUID
    var at: Date
}

enum PeelOutcome: Hashable, Sendable {
    case dropped(PeelMark)
    case refused
}
