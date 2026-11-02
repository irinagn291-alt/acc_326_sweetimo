import Foundation

/// Running team totals. Every field is a fold over CapMarks. Nothing here is persisted.
struct TeamTotals: Hashable, Sendable {
    var madeTwo: Int = 0
    var madeThree: Int = 0
    var freeThrow: Int = 0
    var rebound: Int = 0
    var assist: Int = 0
    var steal: Int = 0
    var block: Int = 0
    var foul: Int = 0
    var turnover: Int = 0

    var points: Int { madeTwo * 2 + madeThree * 3 + freeThrow }

    static func fold(_ caps: [CapMark], bench: Bench? = nil) -> TeamTotals {
        var totals = TeamTotals()
        for cap in caps where bench == nil || cap.jersey.bench == bench {
            switch cap.kind {
            case .madeTwo: totals.madeTwo += 1
            case .madeThree: totals.madeThree += 1
            case .freeThrow: totals.freeThrow += 1
            case .rebound: totals.rebound += 1
            case .assist: totals.assist += 1
            case .steal: totals.steal += 1
            case .block: totals.block += 1
            case .foul: totals.foul += 1
            case .turnover: totals.turnover += 1
            }
        }
        return totals
    }
}

/// One jersey line on the box score. Built by folding CapMarks for that jersey.
struct JerseyLine: Hashable, Sendable, Identifiable {
    var jersey: Jersey
    var totals: TeamTotals

    var id: String { jersey.id }
}

enum TagOutcome: Hashable, Sendable {
    case seated(TagMark)
    case rewritten(TagMark)
    case refused
}

/// Pure folds over the ordered mark log. Seal stops the walk so later marks cannot move totals.
enum SheetFold {
    static func phase(in marks: [SheetMark]) -> Phase {
        var phase = Phase.open
        for mark in marks {
            switch mark {
            case .tag(let tag):
                phase = .tagged(tag.jersey)
            case .cap:
                phase = .open
            case .bare, .peel:
                break
            case .seal:
                return phase
            }
        }
        return phase
    }

    static func capMarks(in marks: [SheetMark]) -> [CapMark] {
        var caps: [CapMark] = []
        for mark in marks {
            switch mark {
            case .cap(let cap):
                caps.append(cap)
            case .peel:
                if caps.isEmpty == false {
                    caps.removeLast()
                }
            case .seal:
                return caps
            case .tag, .bare:
                break
            }
        }
        return caps
    }

    static func seal(in marks: [SheetMark]) -> SealMark? {
        for mark in marks {
            if case .seal(let seal) = mark {
                return seal
            }
        }
        return nil
    }

    static func lines(roster: [Jersey], caps: [CapMark]) -> [JerseyLine] {
        var order: [Jersey] = []
        var seen: Set<String> = []
        for jersey in roster where seen.insert(jersey.id).inserted {
            order.append(jersey)
        }
        for cap in caps where seen.insert(cap.jersey.id).inserted {
            order.append(cap.jersey)
        }
        return order.map { jersey in
            let mine = caps.filter { $0.jersey == jersey }
            return JerseyLine(jersey: jersey, totals: TeamTotals.fold(mine))
        }
    }

    /// Index of the TagMark that is still the open seating, if the rail is Tagged.
    static func openTagIndex(in marks: [SheetMark]) -> Int? {
        guard case .tagged = phase(in: marks) else { return nil }
        for index in marks.indices.reversed() {
            switch marks[index] {
            case .tag:
                return index
            case .cap, .seal:
                return nil
            case .peel, .bare:
                continue
            }
        }
        return nil
    }
}
