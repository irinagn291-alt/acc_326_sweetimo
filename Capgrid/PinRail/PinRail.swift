import Foundation

/// Pin rail. One active tagged jersey. `tag` writes the TagMark that seats it.
/// The sheet decides whether that mark is appended or rewrites the open seating.
struct PinRail: Equatable, Sendable {
    var phase: Phase

    init(phase: Phase = .open) {
        self.phase = phase
    }

    /// Seats `jersey` as a new TagMark. The caller folds it onto the sheet.
    static func tag(_ jersey: Jersey, at: Date = Date(), id: UUID = UUID()) -> TagMark {
        TagMark(id: id, jersey: jersey, at: at)
    }
}
