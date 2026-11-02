import SwiftUI

/// Ordered caps still on the sheet. Undo last is the verb. This is the log frame.
struct PlayTapeScreen: View {
    var showsClose: Bool = false
    @Environment(SheetStore.self) private var store

    var body: some View {
        ScreenScroll {
            DisplayWord(word: "Tape")
            Text(intro)
                .font(TypeFace.body)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if store.saveFault != nil {
                RetryBanner(title: "Save failed.") { Task { await store.flush() } }
            }
            if marks.isEmpty {
                Image("cgr_EmptyHome")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: Spacing.s48 * 4)
                    .clipped()
                    .accessibilityHidden(true)
                Text("No caps yet. Stamp one from the sheet.")
                    .font(TypeFace.body)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(marks.count, format: .number.precision(.fractionLength(0)))
                    .font(TypeFace.figure)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accent)
                    .contentTransition(.numericText(value: Double(marks.count)))
                    .animation(Motion.spring, value: marks.count)
                Text("caps still on this game")
                    .font(TypeFace.callout)
                    .foregroundStyle(Palette.muted)
                VStack(spacing: Spacing.s8) {
                    ForEach(marks) { mark in
                        row(mark)
                    }
                }
            }
            Button("Undo last") { store.peel() }
                .buttonStyle(CapProminentStyle(role: .primary, expands: true))
                .disabled(store.activeSheet?.isLive != true || marks.isEmpty)
            if let refusal = store.lastRefusal {
                Text(refusal)
                    .font(TypeFace.callout)
                    .foregroundStyle(Palette.ink)
            }
        }
        .modifier(CloseChrome(title: "Tape", showsClose: showsClose))
    }

    private var marks: [CapMark] {
        store.activeSheet?.capMarks ?? []
    }

    private var intro: String {
        "Every counted cap, oldest first. Undo last drops only the latest one."
    }

    private func row(_ mark: CapMark) -> some View {
        let title = mark.kind.title
        let number = mark.jersey.number.formatted(.number.precision(.fractionLength(0)))
        return HStack(alignment: .firstTextBaseline, spacing: Spacing.s12) {
            Text(title)
                .font(TypeFace.body)
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("No. \(number)")
                .font(TypeFace.body)
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
                .layoutPriority(1)
            Text(mark.at, format: .dateTime.hour().minute())
                .font(TypeFace.callout)
                .foregroundStyle(Palette.muted)
                .layoutPriority(1)
        }
        .padding(Spacing.s12)
        .hairlineCard()
        .accessibilityElement(children: .combine)
    }
}
