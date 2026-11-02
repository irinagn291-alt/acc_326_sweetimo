import Foundation

/// Simulator seed `cgr.demo.v1`. One live fixture, about 14 CapMarks on jerseys 4, 11, and 23,
/// then a TagMark for jersey 23 so the first frame is Tagged and every cap is enabled.
/// Device builds do not call this.
enum DemoSeed {
    static let key = SheetVault.demoKey

    static func makeArchive(now: Date = Date()) -> SheetArchive {
        let roster = [
            Jersey(number: 4),
            Jersey(number: 11),
            Jersey(number: 23)
        ]
        var sheet = Sheet()
        let start = now.addingTimeInterval(-600)
        let script: [(Int, StatKind)] = [
            (23, .madeTwo),
            (23, .madeTwo),
            (23, .rebound),
            (23, .assist),
            (23, .foul),
            (11, .madeThree),
            (11, .assist),
            (11, .steal),
            (11, .rebound),
            (4, .freeThrow),
            (4, .block),
            (4, .turnover),
            (4, .madeTwo),
            (4, .foul)
        ]
        var cursor = start
        for (number, kind) in script {
            cursor = cursor.addingTimeInterval(20)
            let tagged = sheet.tag(Jersey(number: number), at: cursor)
            sheet = tagged.0
            cursor = cursor.addingTimeInterval(5)
            let stamped = sheet.cap(kind, at: cursor)
            sheet = stamped.0
        }
        cursor = cursor.addingTimeInterval(20)
        let seated = sheet.tag(Jersey(number: 23), at: cursor)
        sheet = seated.0

        let fixture = Fixture(
            id: UUID(uuidString: "C6A10000-0000-4000-8000-000000000023") ?? UUID(),
            home: "Eastside Owls",
            away: "Northgate",
            daykey: Fixture.daykey(for: now),
            roster: roster,
            marks: sheet.marks,
            homeScoreOverride: nil,
            awayScoreOverride: 18
        )
        return SheetArchive(
            fixtures: [fixture],
            roster: roster,
            phase: sheet.phase,
            activeFixtureID: fixture.id,
            onboardingComplete: true,
            periodLengthLabel: "8 min quarters"
        ).reconciled()
    }
}
