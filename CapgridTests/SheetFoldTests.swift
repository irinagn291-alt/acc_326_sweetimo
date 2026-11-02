import XCTest
@testable import Capgrid

final class SheetFoldTests: XCTestCase {
    func testTagFoldsOpenToTaggedAndCapFoldsBackToOpen() {
        var sheet = Sheet()
        XCTAssertEqual(sheet.phase, .open)

        let seated = sheet.tag(Jersey(number: 23), at: date(1), id: uuid(1))
        sheet = seated.0
        guard case .seated(let tag) = seated.1 else {
            return XCTFail("Expected a new TagMark")
        }
        XCTAssertEqual(tag.jersey, Jersey(number: 23))
        XCTAssertEqual(sheet.phase, .tagged(Jersey(number: 23)))

        let stamped = sheet.cap(.madeTwo, at: date(2), id: uuid(2))
        sheet = stamped.0
        guard case .stamped(let cap) = stamped.1 else {
            return XCTFail("Expected a CapMark")
        }
        XCTAssertEqual(cap.jersey, Jersey(number: 23))
        XCTAssertEqual(cap.kind, .madeTwo)
        XCTAssertEqual(sheet.phase, .open)
        XCTAssertEqual(sheet.capMarks, [cap])
    }

    func testTagWhileTaggedRewritesTheOpenTagMark() {
        var sheet = Sheet()
        sheet = sheet.tag(Jersey(number: 23), at: date(1), id: uuid(1)).0
        let rewritten = sheet.tag(Jersey(number: 11), at: date(2), id: uuid(9))
        sheet = rewritten.0
        guard case .rewritten(let tag) = rewritten.1 else {
            return XCTFail("Expected a rewrite")
        }
        XCTAssertEqual(tag.id, uuid(1))
        XCTAssertEqual(tag.jersey, Jersey(number: 11))
        XCTAssertEqual(sheet.marks.count, 1)
        XCTAssertEqual(sheet.phase, .tagged(Jersey(number: 11)))
    }

    func testEmptyPopulatedAndInvalidCap() {
        var sheet = Sheet()
        let empty = sheet.cap(.assist, at: date(1), id: uuid(1))
        sheet = empty.0
        guard case .refused(let bare) = empty.1 else {
            return XCTFail("Cap on an empty open sheet is a BareMark")
        }
        XCTAssertTrue(sheet.capMarks.isEmpty)
        XCTAssertEqual(bare.kind, .assist)
        XCTAssertEqual(sheet.homeTotals.points, 0)

        sheet = sheet.tag(Jersey(number: 4), at: date(2), id: uuid(2)).0
        sheet = sheet.cap(.madeThree, at: date(3), id: uuid(3)).0
        XCTAssertEqual(sheet.capMarks.count, 1)
        XCTAssertEqual(sheet.homeTotals.points, 3)

        let worn = sheet.tag(Jersey(number: 0), at: date(4), id: uuid(4))
        XCTAssertEqual(worn.1, .refused)
        XCTAssertEqual(sheet.phase, .open)

        let away = sheet.tag(Jersey(number: 12, bench: .away), at: date(5), id: uuid(5)).0
        let awayCap = away.cap(.madeTwo, at: date(6), id: uuid(6)).0
        XCTAssertEqual(awayCap.homeTotals.points, 3)
        XCTAssertEqual(awayCap.awayTotals.points, 2)
    }

    func testEmptyRosterWritesBlank() {
        let fixture = Fixture(
            id: uuid(7),
            home: "Eastside Owls",
            away: "Northgate",
            daykey: 20261025,
            roster: [],
            marks: [],
            homeScoreOverride: nil,
            awayScoreOverride: nil
        )
        XCTAssertEqual(fixture.face(), .blank(Blank(fixtureID: uuid(7))))
    }

    func testPeelDropsLastCapAndSealFreezes() {
        var sheet = Sheet()
        sheet = sheet.tag(Jersey(number: 23), at: date(1), id: uuid(1)).0
        sheet = sheet.cap(.madeTwo, at: date(2), id: uuid(2)).0
        sheet = sheet.tag(Jersey(number: 23), at: date(3), id: uuid(3)).0
        sheet = sheet.cap(.foul, at: date(4), id: uuid(4)).0
        XCTAssertEqual(sheet.capMarks.count, 2)

        let peeled = sheet.peel(at: date(5), id: uuid(5))
        sheet = peeled.0
        guard case .dropped(let peel) = peeled.1 else {
            return XCTFail("Expected a peel")
        }
        XCTAssertEqual(peel.droppedCapID, uuid(4))
        XCTAssertEqual(sheet.capMarks.map(\.id), [uuid(2)])
        XCTAssertEqual(sheet.homeTotals.points, 2)
        XCTAssertEqual(sheet.homeTotals.foul, 0)

        let sealed = sheet.seal(at: date(6), id: uuid(6))
        sheet = sealed.0
        XCTAssertEqual(sealed.1, .sealed(SealMark(id: uuid(6), at: date(6))))
        let before = sheet.marks
        XCTAssertEqual(sheet.peel(at: date(7), id: uuid(7)).1, .refused)
        XCTAssertEqual(sheet.marks, before)
        XCTAssertEqual(sheet.capMarks.map(\.id), [uuid(2)])
        let refusedCap = sheet.cap(.assist, at: date(8), id: uuid(8))
        XCTAssertEqual(refusedCap.0.marks, before)
        if case .refused = refusedCap.1 {
        } else {
            XCTFail("Cap after seal is refused")
        }
    }

    func testDaykeyUsesStartOfDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        let evening = Date(timeIntervalSince1970: 1_761_000_000)
        let key = Fixture.daykey(for: evening, calendar: calendar)
        let start = calendar.startOfDay(for: evening)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let expected = (parts.year ?? 0) * 10000 + (parts.month ?? 0) * 100 + (parts.day ?? 0)
        XCTAssertEqual(key, expected)
        XCTAssertGreaterThan(key, 20200101)
    }

    private func date(_ offset: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(1_700_000_000 + offset))
    }

    private func uuid(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", value)) ?? UUID()
    }
}
