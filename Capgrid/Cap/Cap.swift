import Foundation

/// One cell of the cap grid: a stat kind plus how many times it has been stamped.
/// `stamped` is a fold over CapMarks, never a stored counter.
struct Cap: Hashable, Sendable, Identifiable {
    var kind: StatKind
    var stamped: Int

    var id: StatKind { kind }

    static func grid(counting caps: [CapMark]) -> [Cap] {
        StatKind.allCases.map { kind in
            Cap(kind: kind, stamped: caps.filter { $0.kind == kind }.count)
        }
    }
}
