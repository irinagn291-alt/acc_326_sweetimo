import Foundation

/// Cap on a Tagged rail writes this mark: a StatKind on the seated Jersey.
/// Appending it folds the rail back to Open. Totals are a fold over these marks.
struct CapMark: Hashable, Codable, Sendable, Identifiable {
    var id: UUID
    var jersey: Jersey
    var kind: StatKind
    var at: Date
}
