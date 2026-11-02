import XCTest
@testable import Capgrid

/// Family invariant: team points and per-jersey lines are the fold over CapMarks.
/// Peel removes the last cap from that fold. A stored total would be a lie.
final class TotalsTests: XCTestCase {
    func testTotalsEqualTheFoldOverCapMarks() {
        var sheet = Sheet()
        let script: [(Int, StatKind)] = [
            (23, .madeTwo),
            (23, .madeThree),
            (11, .freeThrow),
            (11, .rebound),
            (4, .assist),
            (4, .foul)
        ]
        var stamp = 1
        for (number, kind) in script {
            sheet = sheet.tag(Jersey(number: number), at: Date(timeIntervalSince1970: TimeInterval(stamp)), id: id(stamp)).0
            stamp += 1
            sheet = sheet.cap(kind, at: Date(timeIntervalSince1970: TimeInterval(stamp)), id: id(stamp)).0
            stamp += 1
        }
        let folded = TeamTotals.fold(sheet.capMarks, bench: .home)
        XCTAssertEqual(sheet.homeTotals, folded)
        XCTAssertEqual(sheet.homeTotals.points, 2 + 3 + 1)
        XCTAssertEqual(sheet.homeTotals.rebound, 1)
        XCTAssertEqual(sheet.homeTotals.assist, 1)
        XCTAssertEqual(sheet.homeTotals.foul, 1)

        let lines = sheet.lines(roster: [Jersey(number: 4), Jersey(number: 11), Jersey(number: 23)])
        let jersey23 = lines.first { $0.jersey.number == 23 }
        XCTAssertEqual(jersey23?.totals.points, 5)
        let jersey11 = lines.first { $0.jersey.number == 11 }
        XCTAssertEqual(jersey11?.totals.points, 1)
        XCTAssertEqual(jersey11?.totals.rebound, 1)

        sheet = sheet.peel().0
        XCTAssertEqual(sheet.homeTotals.foul, 0)
        XCTAssertEqual(sheet.homeTotals.points, 6)
        XCTAssertEqual(sheet.homeTotals, TeamTotals.fold(sheet.capMarks, bench: .home))
    }

    /// No match clock. Points do not drift the way a `runStartedAt` clock would.
    /// The box after seal is a PDF fold, not a stored total.
    @MainActor
    func testFoldIgnoresClockAndExportsPDF() {
        var morning = Sheet()
        morning = morning.tag(Jersey(number: 23), at: Date(timeIntervalSince1970: 10), id: id(21)).0
        morning = morning.cap(.madeTwo, at: Date(timeIntervalSince1970: 20), id: id(22)).0
        var evening = Sheet()
        evening = evening.tag(Jersey(number: 23), at: Date(timeIntervalSince1970: 80_000), id: id(23)).0
        evening = evening.cap(.madeTwo, at: Date(timeIntervalSince1970: 90_000), id: id(24)).0
        XCTAssertEqual(morning.homeTotals.points, evening.homeTotals.points)
        XCTAssertEqual(morning.homeTotals.points, 2)

        let sealed = morning.seal(at: Date(timeIntervalSince1970: 30), id: id(25)).0
        let fixture = Fixture(
            id: id(26),
            home: "Eastside Owls",
            away: "Northgate",
            daykey: 20261025,
            roster: [Jersey(number: 23)],
            marks: sealed.marks,
            homeScoreOverride: nil,
            awayScoreOverride: nil
        )
        let pdf = BoxScorePDF.render(fixture: fixture, period: "8 min quarters")
        XCTAssertGreaterThan(pdf.count, 32)
        XCTAssertEqual(pdf.prefix(4), Data("%PDF".utf8))
    }

    func testSeedEndsTaggedOnJersey23WithFourteenCaps() {
        let archive = DemoSeed.makeArchive(now: Date(timeIntervalSince1970: 1_761_360_000))
        let fixture = archive.fixtures.first
        XCTAssertEqual(fixture?.home, "Eastside Owls")
        XCTAssertEqual(fixture?.away, "Northgate")
        XCTAssertEqual(archive.onboardingComplete, true)
        XCTAssertEqual(archive.phase, .tagged(Jersey(number: 23)))
        guard case .sheet(let sheet) = fixture?.face() else {
            return XCTFail("Seeded roster must write a sheet")
        }
        XCTAssertEqual(sheet.capMarks.count, 14)
        XCTAssertTrue(sheet.capsEnabled)
        XCTAssertEqual(sheet.homeTotals, TeamTotals.fold(sheet.capMarks))
        XCTAssertGreaterThan(sheet.homeTotals.points, 0)
    }

    private func id(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", value)) ?? UUID()
    }
}
