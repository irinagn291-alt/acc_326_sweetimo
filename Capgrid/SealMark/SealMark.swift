import Foundation

/// Seal freezes CapMarks for export. Later tag, cap, and peel do not change the fold.
struct SealMark: Hashable, Codable, Sendable, Identifiable {
    var id: UUID
    var at: Date
}

enum SealOutcome: Hashable, Sendable {
    case sealed(SealMark)
    case refused
}
