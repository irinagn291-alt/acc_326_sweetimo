import SwiftUI

/// Home is the sheet. The pin rail stays up, the cap grid is the verb, totals fold underneath.
struct SheetView: View {
    @Environment(SheetStore.self) private var store
    @Binding var deck: Deck?
    @State private var flight: StatKind?
    @State private var confirmSeal = false

    var body: some View {
        Group {
            if let fixture = store.archive.activeFixture, store.activeSheet != nil {
                live(fixture)
            } else if store.archive.activeFixture != nil {
                VStack(spacing: Spacing.s8) {
                    chrome.padding(.horizontal, Spacing.s16).padding(.top, Spacing.s8)
                    EmptyPage(
                        imageName: "cgr_EmptyHome",
                        title: "Sheet",
                        line: "Add a number before the first cap.",
                        actionTitle: "Add a number",
                        action: { deck = .pad }
                    )
                }
            } else {
                VStack(spacing: Spacing.s8) {
                    chrome.padding(.horizontal, Spacing.s16).padding(.top, Spacing.s8)
                    EmptyPage(
                        imageName: "cgr_EmptyHome",
                        title: "Sheet",
                        line: "No game yet. Add the two teams, then tag a number.",
                        actionTitle: "Add a game",
                        action: { deck = .matches }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.bg.ignoresSafeArea())
        .sensoryFeedback(.success, trigger: store.successCommits)
        .confirmationDialog(
            "Seal this game?",
            isPresented: $confirmSeal,
            titleVisibility: .visible
        ) {
            Button("Seal") { store.seal() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Caps stay as they are. You can still read the box.")
        }
    }

    /// Rail and grid stay put. Totals and seal sit below and scroll on their own.
    private func live(_ fixture: Fixture) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s16) {
            chrome
            DisplayWord(word: "Sheet")
            status
            lastStamp
            PinRailView(
                roster: fixture.roster,
                phase: store.phase,
                flightChip: flight?.chip,
                onTag: { store.tag($0) },
                onPad: { deck = .pad }
            )
            CapGrid(
                caps: store.capGrid,
                capsLive: store.capsEnabled,
                interactive: store.activeSheet?.isLive == true,
                flight: flight,
                onFlight: { flight = $0 },
                onStamp: { store.cap($0) }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(1)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s16) {
                    TotalsStrip(
                        homeName: fixture.home,
                        awayName: fixture.away,
                        home: store.homeTotals,
                        away: store.awayTotals,
                        canSeal: store.activeSheet?.isLive == true,
                        onSeal: { confirmSeal = true }
                    )
                    Button("Undo last") { store.peel() }
                        .buttonStyle(CapProminentStyle(role: .secondary, expands: true))
                        .disabled(canUndo == false)
                    Button("Play tape") { deck = .tape }
                        .buttonStyle(CapProminentStyle(role: .secondary, expands: true))
                }
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.top, Spacing.s8)
        .padding(.bottom, Spacing.s24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var canUndo: Bool {
        store.activeSheet?.isLive == true && store.activeSheet?.capMarks.isEmpty == false
    }

    private var chrome: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.s8) {
                chromeButtons
            }
            VStack(alignment: .leading, spacing: Spacing.s8) {
                chromeButtons
            }
        }
    }

    @ViewBuilder
    private var chromeButtons: some View {
        Button("Matches") { deck = .matches }
            .buttonStyle(CapProminentStyle(role: .secondary))
        Button("Insights") { deck = .insights }
            .buttonStyle(CapProminentStyle(role: .secondary))
        Button("Settings") { deck = .settings }
            .buttonStyle(CapProminentStyle(role: .secondary))
    }

    private var status: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text(statusLine)
                .font(TypeFace.body)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let refusal = store.lastRefusal {
                Text(refusal)
                    .font(TypeFace.callout)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let notice = store.notice {
                Text(notice)
                    .font(TypeFace.callout)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if store.saveFault != nil {
                RetryBanner(title: "Save failed.") { Task { await store.flush() } }
            }
        }
    }

    private var statusLine: String {
        if store.activeSheet?.isLive == false {
            return "Game sealed. Caps stay."
        }
        switch store.phase {
        case .open:
            return "Tag a number, then stamp."
        case .tagged(let seated):
            let number = seated.number
            return "Number \(number) tagged. Stamp a cap."
        }
    }

    @ViewBuilder
    private var lastStamp: some View {
        if let last = store.activeSheet?.capMarks.last {
            let title = last.kind.title
            let number = last.jersey.number
            Text("Last stamp. \(title), number \(number).")
                .font(TypeFace.callout)
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
