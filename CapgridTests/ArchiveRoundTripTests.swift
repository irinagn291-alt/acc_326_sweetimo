import XCTest
@testable import Capgrid

@MainActor
final class ArchiveRoundTripTests: XCTestCase {
    func testWriteReloadAndVerify() async {
        let harness = StoreHarness.make()
        let when = Date(timeIntervalSince1970: 1_761_400_000)
        harness.store.addFixture(
            home: "Eastside Owls",
            away: "Northgate",
            roster: [Jersey(number: 23), Jersey(number: 4)],
            at: when,
            id: StoreHarness.id(1)
        )
        harness.store.tag(Jersey(number: 23), at: when, id: StoreHarness.id(2))
        harness.store.cap(.madeTwo, at: when.addingTimeInterval(5), id: StoreHarness.id(3))
        harness.store.cap(.rebound, at: when.addingTimeInterval(6), id: StoreHarness.id(4))
        await harness.store.flush()

        let reloaded = StoreHarness.reopen(harness)
        await reloaded.store.bootstrap(seedDemo: false)
        let fixture = reloaded.store.archive.activeFixture
        XCTAssertEqual(fixture?.home, "Eastside Owls")
        XCTAssertEqual(fixture?.daykey, Fixture.daykey(for: when))
        let phase = reloaded.store.phase
        let points = reloaded.store.homeTotals.points
        let rebounds = reloaded.store.homeTotals.rebound
        XCTAssertEqual(phase, .open)
        XCTAssertEqual(points, 2)
        XCTAssertEqual(rebounds, 0)
        let caps = reloaded.store.activeSheet?.capMarks.map(\.kind)
        XCTAssertEqual(caps, [.madeTwo])

        let data = await reloaded.vault.load()
        let encoded = try? ArchiveCoding.encode(data.archive)
        let text = encoded.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        XCTAssertTrue(text.contains("\"schemaVersion\":1"))
        XCTAssertFalse(text.contains("\"points\""))
        XCTAssertFalse(text.contains("madeTwoCount"))
    }

    func testCorruptFileFallsBackToBackupThenEmpty() async throws {
        let harness = StoreHarness.make()
        harness.store.addFixture(
            home: "Eastside Owls",
            away: "Northgate",
            roster: [Jersey(number: 11)],
            id: StoreHarness.id(5)
        )
        await harness.store.flush()

        let file = harness.directory.appendingPathComponent(SheetVault.fileName)
        let backup = harness.directory.appendingPathComponent(SheetVault.fileName + ".backup")
        let good = try Data(contentsOf: file)
        try good.write(to: backup, options: .atomic)
        try Data("not-json".utf8).write(to: file, options: .atomic)

        let restored = await harness.vault.load()
        XCTAssertEqual(restored.usedBackup, true)
        XCTAssertEqual(restored.archive.fixtures.first?.home, "Eastside Owls")

        try Data("still-bad".utf8).write(to: backup, options: .atomic)
        await harness.vault.setMirroredArchive(Data("nope".utf8))
        let empty = await harness.vault.load()
        XCTAssertTrue(empty.archive.fixtures.isEmpty)
        XCTAssertEqual(empty.notice, "The box score file was unreadable. Started a fresh sheet.")
    }

    func testResetClearsTheArchive() async {
        let harness = StoreHarness.make()
        harness.store.addFixture(
            home: "Eastside Owls",
            away: "Northgate",
            roster: [Jersey(number: 23)],
            id: StoreHarness.id(6)
        )
        await harness.store.flush()
        await harness.store.resetAllData()
        let loaded = await harness.vault.load()
        XCTAssertTrue(loaded.archive.fixtures.isEmpty)
        let mirrored = await harness.vault.mirroredArchive()
        XCTAssertNil(mirrored)
    }
}
