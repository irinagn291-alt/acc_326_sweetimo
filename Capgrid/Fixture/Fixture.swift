import Foundation

/// Match in the box-score lexicon. Home and away names, a daykey, a roster, and ordered marks.
/// `sealed` is the SealMark folded out of the log. Score overrides are the volunteer's typed
/// score on the match list. They are not team totals.
struct Fixture: Hashable, Codable, Sendable, Identifiable {
    var id: UUID
    var home: String
    var away: String
    /// YYYYMMDD from `Calendar.current.startOfDay`.
    var daykey: Int
    var roster: [Jersey]
    var marks: [SheetMark]
    var homeScoreOverride: Int?
    var awayScoreOverride: Int?

    var sealed: SealMark? {
        Sheet(marks: marks).seal
    }

    /// Empty roster is Blank. A roster writes a Sheet even when the log is still empty.
    func face() -> FixtureFace {
        if roster.isEmpty {
            return .blank(Blank(fixtureID: id))
        }
        return .sheet(Sheet(marks: marks))
    }

    static func daykey(for date: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return year * 10000 + month * 100 + day
    }
}

/// What the home surface reads. Blank is not an empty sheet.
enum FixtureFace: Hashable, Sendable {
    case blank(Blank)
    case sheet(Sheet)
}
