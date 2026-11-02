import Foundation

/// Tag writes this mark. It seats a Jersey on the pin rail and folds Open to Tagged.
/// Tag while Tagged rewrites this mark in place instead of stacking a second seat.
struct TagMark: Hashable, Codable, Sendable, Identifiable {
    var id: UUID
    var jersey: Jersey
    var at: Date
}
