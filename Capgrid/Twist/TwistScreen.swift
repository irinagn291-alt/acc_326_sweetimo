import SwiftUI

/// Tag, then cap. The tagged number and a stamp sit on this screen.
struct TwistScreen: View {
    var showsClose: Bool = false
    @Environment(SheetStore.self) private var store
    @State private var flight: StatKind?

    var body: some View {
        ScreenScroll {
            DisplayWord(word: "Stamp")
            Text(status)
                .font(TypeFace.body)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("A stamp opens the next number.")
                .font(TypeFace.title)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let fixture = store.archive.activeFixture {
                PinRailView(
                    roster: fixture.roster,
                    phase: store.phase,
                    flightChip: flight?.chip,
                    onTag: { store.tag($0) }
                )
            }
            HStack(alignment: .top, spacing: Spacing.s12) {
                ForEach(stampCaps) { cap in
                    CapButton(
                        cap: cap,
                        prominent: cap.kind.pointsVerb && store.capsEnabled,
                        enabled: canStamp,
                        onFlight: { active in
                            flight = active ? cap.kind : nil
                        },
                        onStamp: { store.cap(cap.kind) }
                    )
                }
            }
            .frame(maxWidth: .infinity, minHeight: Spacing.s48 * 3, alignment: .topLeading)
            if let last = store.activeSheet?.capMarks.last {
                let title = last.kind.title
                let number = last.jersey.number
                Text("Last stamp. \(title), number \(number).")
                    .font(TypeFace.callout)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .modifier(CloseChrome(title: "Stamp", showsClose: showsClose))
    }

    private var canStamp: Bool {
        store.activeSheet?.isLive == true
    }

    private var stampCaps: [Cap] {
        let kinds: [StatKind] = [.madeTwo, .madeThree, .freeThrow]
        let grid = store.capGrid
        return kinds.map { kind in
            grid.first { $0.kind == kind } ?? Cap(kind: kind, stamped: 0)
        }
    }

    private var status: String {
        switch store.phase {
        case .open:
            "Tag a number, then stamp."
        case .tagged(let seated):
            "Number \(seated.number) tagged. Stamp a cap."
        }
    }
}
