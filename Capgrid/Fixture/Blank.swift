import Foundation

/// A Fixture with an empty roster writes Blank instead of a Sheet.
/// There is nothing to tag and nothing to fold until a jersey is on the roster.
struct Blank: Hashable, Sendable {
    var fixtureID: UUID
}
