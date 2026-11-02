import SwiftUI

/// Both benches, large. Points are the fold. This is the goals frame, not the keypad.
struct GoalsScreen: View {
    var showsClose: Bool = false
    @Environment(SheetStore.self) private var store

    var body: some View {
        ScreenScroll {
            DisplayWord(word: "Totals")
            Text("Points, rebounds, and fouls add up after each stamp.")
                .font(TypeFace.body)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let fixture = store.archive.activeFixture, store.activeSheet != nil {
                teamBlock(name: fixture.home, totals: store.homeTotals, prominent: true)
                teamBlock(name: fixture.away, totals: store.awayTotals, prominent: false)
                if store.jerseyLines.isEmpty {
                    Text("No caps yet. Tag a number, then stamp.")
                        .font(TypeFace.body)
                        .foregroundStyle(Palette.ink)
                } else {
                    VStack(spacing: Spacing.s8) {
                        ForEach(store.jerseyLines) { line in
                            lineRow(line)
                        }
                    }
                }
            } else {
                Text("No game yet. Add one from Matches.")
                    .font(TypeFace.body)
                    .foregroundStyle(Palette.ink)
            }
            if store.saveFault != nil {
                RetryBanner(title: "Save failed.") { Task { await store.flush() } }
            }
        }
        .modifier(CloseChrome(title: "Totals", showsClose: showsClose))
    }

    private func teamBlock(name: String, totals: TeamTotals, prominent: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text(name)
                .font(TypeFace.callout)
                .foregroundStyle(Palette.muted)
                .lineLimit(1)
                .truncationMode(.tail)
            PointsText(value: totals.points, prominent: prominent)
            Text(detail(totals))
                .font(TypeFace.callout)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hairlineCard()
    }

    private func detail(_ totals: TeamTotals) -> String {
        let made = totals.madeTwo + totals.madeThree + totals.freeThrow
        let shots = made.formatted(.number.precision(.fractionLength(0)))
        let boards = totals.rebound.formatted(.number.precision(.fractionLength(0)))
        let fouls = totals.foul.formatted(.number.precision(.fractionLength(0)))
        return "\(shots) made shots, \(boards) rebounds, \(fouls) fouls"
    }

    private func lineRow(_ line: JerseyLine) -> some View {
        let number = line.jersey.number.formatted(.number.precision(.fractionLength(0)))
        let side = line.jersey.bench == .home ? "Home side" : "Away side"
        return HStack(alignment: .firstTextBaseline, spacing: Spacing.s12) {
            Text("No. \(number)")
                .font(TypeFace.body)
                .foregroundStyle(Palette.ink)
                .layoutPriority(1)
            Text(side)
                .font(TypeFace.callout)
                .foregroundStyle(Palette.muted)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(line.totals.points, format: .number.precision(.fractionLength(0)))
                .font(TypeFace.title)
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
                .contentTransition(.numericText(value: Double(line.totals.points)))
                .layoutPriority(1)
        }
        .padding(Spacing.s12)
        .hairlineCard()
    }
}
