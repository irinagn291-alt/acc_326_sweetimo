import Foundation

/// A Sheet is a pure fold over an ordered list of marks.
/// Tag seats a Jersey and folds Open to Tagged. Cap on Tagged appends a CapMark and folds back to Open.
/// Cap on Open appends a BareMark and returns a refusal. Peel drops the last CapMark while Live.
/// Seal freezes the CapMarks. Team totals are `TeamTotals.fold` and are not stored on the sheet.
struct Sheet: Hashable, Sendable {
    private(set) var marks: [SheetMark]

    init(marks: [SheetMark] = []) {
        self.marks = marks
    }

    var phase: Phase { SheetFold.phase(in: marks) }
    var capMarks: [CapMark] { SheetFold.capMarks(in: marks) }
    var seal: SealMark? { SheetFold.seal(in: marks) }
    var isLive: Bool { seal == nil }
    var capsEnabled: Bool {
        if case .tagged = phase, isLive { return true }
        return false
    }

    var homeTotals: TeamTotals { TeamTotals.fold(capMarks, bench: .home) }
    var awayTotals: TeamTotals { TeamTotals.fold(capMarks, bench: .away) }

    func lines(roster: [Jersey]) -> [JerseyLine] {
        SheetFold.lines(roster: roster, caps: capMarks)
    }

    func caps() -> [Cap] {
        Cap.grid(counting: capMarks)
    }

    /// Tag writes a TagMark. While Tagged, the open TagMark is rewritten and the rail stays Tagged.
    func tag(_ jersey: Jersey, at: Date = Date(), id: UUID = UUID()) -> (Sheet, TagOutcome) {
        guard isLive else { return (self, .refused) }
        guard jersey.isWearable else { return (self, .refused) }
        var next = self
        if let index = SheetFold.openTagIndex(in: marks), case .tag(var existing) = marks[index] {
            existing.jersey = jersey
            existing.at = at
            next.marks[index] = .tag(existing)
            return (next, .rewritten(existing))
        }
        let mark = PinRail.tag(jersey, at: at, id: id)
        next.marks.append(.tag(mark))
        return (next, .seated(mark))
    }

    /// Cap on Tagged stamps. Cap on Open writes BareMark and adds no CapMark.
    func cap(_ kind: StatKind, at: Date = Date(), id: UUID = UUID()) -> (Sheet, CapOutcome) {
        guard isLive else {
            let bare = BareMark(id: id, kind: kind, at: at)
            return (self, .refused(bare))
        }
        guard case .tagged(let jersey) = phase else {
            var next = self
            let bare = BareMark(id: id, kind: kind, at: at)
            next.marks.append(.bare(bare))
            return (next, .refused(bare))
        }
        var next = self
        let mark = CapMark(id: id, jersey: jersey, kind: kind, at: at)
        next.marks.append(.cap(mark))
        return (next, .stamped(mark))
    }

    /// Peel drops the last effective CapMark only while the sheet is Live.
    func peel(at: Date = Date(), id: UUID = UUID()) -> (Sheet, PeelOutcome) {
        guard isLive, let last = capMarks.last else { return (self, .refused) }
        var next = self
        let mark = PeelMark(id: id, droppedCapID: last.id, at: at)
        next.marks.append(.peel(mark))
        return (next, .dropped(mark))
    }

    /// Seal freezes CapMarks. A second seal is refused.
    func seal(at: Date = Date(), id: UUID = UUID()) -> (Sheet, SealOutcome) {
        guard isLive else { return (self, .refused) }
        var next = self
        let mark = SealMark(id: id, at: at)
        next.marks.append(.seal(mark))
        return (next, .sealed(mark))
    }
}
