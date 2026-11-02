import SwiftUI

/// Games on this phone. Pick one, type a final score, or add the next pair of teams.
struct MatchesView: View {
    var showsClose: Bool = false
    @Environment(SheetStore.self) private var store
    @State private var homeName = ""
    @State private var awayName = ""
    @State private var homeScore = ""
    @State private var awayScore = ""
    @State private var composing = false
    @FocusState private var focus: Field?

    private enum Field: Hashable {
        case home
        case away
        case homeScore
        case awayScore
    }

    var body: some View {
        TimelineView(.everyMinute) { context in
            Group {
                if store.archive.fixtures.isEmpty && composing == false {
                    EmptyPage(
                        imageName: "cgr_EmptyMatches",
                        title: "Matches",
                        line: "No game yet. Name the two teams and add the game.",
                        actionTitle: "Add a game",
                        action: { composing = true }
                    )
                } else {
                    ScreenScroll {
                        DisplayWord(word: "Matches")
                        Text("Line up the next game, or correct a final score by hand.")
                            .font(TypeFace.body)
                            .foregroundStyle(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        if store.saveFault != nil {
                            RetryBanner(title: "Save failed.") { Task { await store.flush() } }
                        }
                        if store.archive.fixtures.isEmpty == false {
                            list(now: context.date)
                            scoreEditor
                        }
                        newGame
                    }
                    .scrollDismissesKeyboard(.immediately)
                }
            }
        }
        .modifier(CloseChrome(title: "Matches", showsClose: showsClose))
        .onAppear(perform: reloadScores)
        .onChange(of: store.archive.activeFixtureID) { _, _ in reloadScores() }
        .onChange(of: homeScore) { _, new in
            let clean = ScoreInput.digits(from: new)
            if clean != new { homeScore = clean }
            pushScores(home: clean, away: awayScore)
        }
        .onChange(of: awayScore) { _, new in
            let clean = ScoreInput.digits(from: new)
            if clean != new { awayScore = clean }
            pushScores(home: homeScore, away: clean)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
                    .frame(minHeight: Hit.min)
            }
        }
    }

    private func list(now: Date) -> some View {
        VStack(spacing: Spacing.s8) {
            ForEach(store.archive.fixtures) { fixture in
                Button {
                    store.select(fixtureID: fixture.id)
                } label: {
                    row(fixture, now: now)
                }
                .buttonStyle(CapProminentStyle(role: .secondary, expands: true))
                .accessibilityHint(fixture.id == store.archive.activeFixtureID ? "On the sheet" : "Show this game")
            }
        }
    }

    private func row(_ fixture: Fixture, now: Date) -> some View {
        HStack(alignment: .center, spacing: Spacing.s12) {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                Text(fixture.home)
                    .font(TypeFace.body)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(fixture.away)
                    .font(TypeFace.callout)
                    .foregroundStyle(Palette.muted)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(dayLine(fixture, now: now))
                    .font(TypeFace.caption)
                    .foregroundStyle(Palette.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: Spacing.s4) {
                Text(running(fixture), format: .number.precision(.fractionLength(0)))
                    .font(TypeFace.title)
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
                    .layoutPriority(1)
                if fixture.id == store.archive.activeFixtureID {
                    Text("On the sheet")
                        .font(TypeFace.caption)
                        .foregroundStyle(Palette.accent)
                }
            }
        }
        .contentShape(Rectangle())
    }

    private var scoreEditor: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("Typed final score")
                .font(TypeFace.callout)
                .foregroundStyle(Palette.muted)
            Text(scoreCaption)
                .font(TypeFace.caption)
                .foregroundStyle(Palette.ink)
            HStack(spacing: Spacing.s8) {
                scoreField("Home score", text: $homeScore, field: .homeScore, next: .awayScore)
                scoreField("Away score", text: $awayScore, field: .awayScore, next: nil)
            }
        }
        .padding(Spacing.s16)
        .hairlineCard()
    }

    private var scoreCaption: String {
        if store.archive.activeFixture?.homeScoreOverride == nil
            && store.archive.activeFixture?.awayScoreOverride == nil {
            return "Typed score is unknown until you enter it. The running total stays on the sheet."
        }
        return "Entered by hand. It does not change the running total."
    }

    private func scoreField(_ title: String, text: Binding<String>, field: Field, next: Field?) -> some View {
        TextField(title, text: text)
            .font(TypeFace.body)
            .keyboardType(.numberPad)
            .padding(Spacing.s12)
            .frame(minHeight: Hit.min)
            .hairlineChip()
            .focused($focus, equals: field)
            .submitLabel(next == nil ? .done : .next)
            .onSubmit {
                if let next { focus = next } else { focus = nil }
            }
    }

    private var newGame: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("New game")
                .font(TypeFace.title)
                .foregroundStyle(Palette.ink)
            TextField("Home team", text: $homeName)
                .font(TypeFace.body)
                .textInputAutocapitalization(.words)
                .padding(Spacing.s12)
                .frame(minHeight: Hit.min)
                .hairlineChip()
                .focused($focus, equals: .home)
                .submitLabel(.next)
                .onSubmit { focus = .away }
            TextField("Away team", text: $awayName)
                .font(TypeFace.body)
                .textInputAutocapitalization(.words)
                .padding(Spacing.s12)
                .frame(minHeight: Hit.min)
                .hairlineChip()
                .focused($focus, equals: .away)
                .submitLabel(.done)
                .onSubmit { focus = nil }
            Button("Add game", action: add)
                .buttonStyle(CapProminentStyle(role: .primary, expands: true))
                .disabled(canAdd == false)
        }
        .padding(Spacing.s16)
        .hairlineCard()
    }

    private var canAdd: Bool {
        homeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            && awayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    private func add() {
        let home = homeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let away = awayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard home.isEmpty == false, away.isEmpty == false else { return }
        store.addFixture(home: home, away: away, roster: store.archive.roster, at: Date())
        homeName = ""
        awayName = ""
        focus = nil
    }

    private func reloadScores() {
        homeScore = store.archive.activeFixture?.homeScoreOverride.map(String.init) ?? ""
        awayScore = store.archive.activeFixture?.awayScoreOverride.map(String.init) ?? ""
    }

    private func pushScores(home: String, away: String) {
        guard store.archive.activeFixture != nil else { return }
        store.setScoreOverride(home: ScoreInput.value(from: home), away: ScoreInput.value(from: away))
    }

    private func running(_ fixture: Fixture) -> Int {
        switch fixture.face() {
        case .blank:
            return 0
        case .sheet(let sheet):
            return sheet.homeTotals.points
        }
    }

    private func dayLine(_ fixture: Fixture, now: Date) -> String {
        let calendar = Calendar.current
        if fixture.daykey == Fixture.daykey(for: now, calendar: calendar) {
            return "Today"
        }
        guard let date = DayKey.date(from: fixture.daykey, calendar: calendar) else {
            return "unknown"
        }
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }
}
