import Foundation

/// State between the archive and the UI. Views will read this. They will not read the vault.
/// Mutations go through the sheet fold, then a debounced save. Memory stays ahead of the file.
@MainActor
@Observable
final class SheetStore {
    private(set) var archive: SheetArchive
    private(set) var notice: String?
    private(set) var saveFault: ArchiveFault?
    /// Increments only when a CapMark is appended. A refused cap does not move it.
    private(set) var successCommits: Int = 0
    private(set) var lastRefusal: String?
    /// False until the first load (and the Simulator seed, when it runs) has landed.
    private(set) var isReady = false

    private let vault: SheetVault
    private var saveTask: Task<Void, Never>?
    private var revision: Int = 0
    private var bootstrapped = false

    init(vault: SheetVault, archive: SheetArchive = SheetArchive()) {
        self.vault = vault
        self.archive = archive
    }

    convenience init() {
        self.init(vault: SheetVault(directory: SheetVault.applicationSupport(), defaults: .standard))
    }

    var phase: Phase { archive.phase }

    var activeFace: FixtureFace? {
        guard let fixture = archive.activeFixture else { return nil }
        return fixture.face()
    }

    var activeSheet: Sheet? {
        if case .sheet(let sheet) = activeFace { return sheet }
        return nil
    }

    var capsEnabled: Bool { activeSheet?.capsEnabled ?? false }

    var homeTotals: TeamTotals { activeSheet?.homeTotals ?? TeamTotals() }
    var awayTotals: TeamTotals { activeSheet?.awayTotals ?? TeamTotals() }

    var jerseyLines: [JerseyLine] {
        guard let fixture = archive.activeFixture, let sheet = activeSheet else { return [] }
        return sheet.lines(roster: fixture.roster)
    }

    var capGrid: [Cap] { activeSheet?.caps() ?? Cap.grid(counting: []) }

    func bootstrap(seedDemo: Bool = true) async {
        guard bootstrapped == false else { return }
        bootstrapped = true
        let loaded = await vault.load()
        archive = loaded.archive
        notice = loaded.notice
        #if targetEnvironment(simulator)
        if seedDemo, await vault.demoAlreadyApplied() == false, archive.fixtures.isEmpty {
            archive = DemoSeed.makeArchive()
            await vault.markDemoApplied()
            _ = await vault.save(archive)
        }
        #endif
        isReady = true
    }

    func tag(_ jersey: Jersey, at: Date = Date(), id: UUID = UUID()) {
        mutate { sheet in
            let (next, outcome) = sheet.tag(jersey, at: at, id: id)
            switch outcome {
            case .seated, .rewritten:
                lastRefusal = nil
            case .refused:
                lastRefusal = "That number cannot be tagged on this sheet."
            }
            return next
        }
    }

    /// Pad path. Seats the number on the live roster (and the defaults), then tags it.
    /// An empty roster is Blank until this appends, so the chip appears and the sheet opens.
    func seatAndTag(_ jersey: Jersey, at: Date = Date(), id: UUID = UUID()) {
        guard jersey.isWearable else { return }
        guard let index = activeIndex else {
            lastRefusal = "Start a game, then tag a number."
            return
        }
        if archive.fixtures[index].roster.contains(where: { $0.id == jersey.id }) == false {
            archive.fixtures[index].roster.append(jersey)
        }
        if archive.roster.contains(where: { $0.id == jersey.id }) == false {
            archive.roster.append(jersey)
        }
        tag(jersey, at: at, id: id)
    }

    func cap(_ kind: StatKind, at: Date = Date(), id: UUID = UUID()) {
        mutate { sheet in
            let (next, outcome) = sheet.cap(kind, at: at, id: id)
            switch outcome {
            case .stamped:
                successCommits += 1
                lastRefusal = nil
            case .refused:
                lastRefusal = "Tag a number, then stamp the cap."
            }
            return next
        }
    }

    func peel(at: Date = Date(), id: UUID = UUID()) {
        mutate { sheet in
            let (next, outcome) = sheet.peel(at: at, id: id)
            if case .refused = outcome {
                lastRefusal = sheet.isLive
                    ? "Nothing to undo yet."
                    : "The sheet is sealed. Caps stay."
            } else {
                lastRefusal = nil
            }
            return next
        }
    }

    func seal(at: Date = Date(), id: UUID = UUID()) {
        mutate { sheet in
            let (next, outcome) = sheet.seal(at: at, id: id)
            if case .refused = outcome {
                lastRefusal = "This sheet is already sealed."
            } else {
                lastRefusal = nil
            }
            return next
        }
    }

    /// Adds a fixture. An empty roster writes Blank and does not invent a sheet log.
    func addFixture(home: String, away: String, roster: [Jersey], at: Date = Date(), id: UUID = UUID()) {
        let fixture = Fixture(
            id: id,
            home: home,
            away: away,
            daykey: Fixture.daykey(for: at),
            roster: roster,
            marks: [],
            homeScoreOverride: nil,
            awayScoreOverride: nil
        )
        archive.fixtures.append(fixture)
        archive.activeFixtureID = fixture.id
        archive.roster = roster
        archive = archive.reconciled()
        lastRefusal = nil
        scheduleSave()
    }

    func setScoreOverride(home: Int?, away: Int?) {
        guard let index = activeIndex else { return }
        archive.fixtures[index].homeScoreOverride = home
        archive.fixtures[index].awayScoreOverride = away
        scheduleSave()
    }

    func select(fixtureID: UUID) {
        guard archive.fixtures.contains(where: { $0.id == fixtureID }) else { return }
        archive.activeFixtureID = fixtureID
        archive = archive.reconciled()
        scheduleSave()
    }

    func updatePeriodLength(_ label: String) {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        archive.periodLengthLabel = trimmed
        scheduleSave()
    }

    func addRosterNumber(_ number: Int, bench: Bench = .home) {
        let jersey = Jersey(number: number, bench: bench)
        guard jersey.isWearable else { return }
        guard archive.roster.contains(where: { $0.id == jersey.id }) == false else { return }
        archive.roster.append(jersey)
        scheduleSave()
    }

    func removeRosterNumber(_ jersey: Jersey) {
        archive.roster.removeAll { $0.id == jersey.id }
        scheduleSave()
    }

    func completeOnboarding() {
        archive.onboardingComplete = true
        if archive.periodLengthLabel.isEmpty {
            archive.periodLengthLabel = "8 min quarters"
        }
        scheduleSave()
    }

    func noteSceneInactive() {
        saveTask?.cancel()
        saveTask = Task { await self.flush() }
    }

    func flush() async {
        saveTask?.cancel()
        let token = revision
        let snapshot = archive
        let fault = await vault.save(snapshot)
        guard token == revision else { return }
        saveFault = fault
    }

    func resetAllData() async {
        saveTask?.cancel()
        revision += 1
        let fault = await vault.reset()
        archive = SheetArchive()
        notice = nil
        saveFault = fault
        lastRefusal = nil
    }

    private var activeIndex: Int? {
        guard let id = archive.activeFixtureID else { return nil }
        return archive.fixtures.firstIndex { $0.id == id }
    }

    private func mutate(_ body: (Sheet) -> Sheet) {
        guard let index = activeIndex else {
            lastRefusal = "Start a game, then tag a number."
            return
        }
        let fixture = archive.fixtures[index]
        guard case .sheet(let sheet) = fixture.face() else {
            lastRefusal = "Add a number to the roster before tagging."
            return
        }
        let next = body(sheet)
        archive.fixtures[index].marks = next.marks
        archive = archive.reconciled()
        scheduleSave()
    }

    private func scheduleSave() {
        revision += 1
        let token = revision
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard let self, Task.isCancelled == false, token == self.revision else { return }
            let snapshot = self.archive
            let fault = await self.vault.save(snapshot)
            guard Task.isCancelled == false, token == self.revision else { return }
            self.saveFault = fault
        }
    }
}
