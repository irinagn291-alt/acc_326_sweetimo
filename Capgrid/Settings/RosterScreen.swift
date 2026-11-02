import SwiftUI

/// Default numbers for the next game. The live sheet keeps the numbers it already has.
struct RosterScreen: View {
    var showsClose: Bool = false
    @Environment(SheetStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var digits = ""
    @State private var away = false
    @State private var pending: Jersey?
    @FocusState private var numberFocus: Bool

    var body: some View {
        Group {
            if showsClose {
                NavigationStack { core }
            } else {
                core
            }
        }
    }

    private var core: some View {
        ScreenScroll {
            DisplayWord(word: "Roster")
            Text("These numbers are ready for the next game. Removing one leaves the current sheet alone.")
                .font(TypeFace.body)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if store.archive.roster.isEmpty {
                Text("No numbers yet. Add one to start a sheet.")
                    .font(TypeFace.body)
                    .foregroundStyle(Palette.ink)
            } else {
                VStack(spacing: Spacing.s8) {
                    ForEach(store.archive.roster) { player in
                        let number = player.number.formatted(.number.precision(.fractionLength(0)))
                        let side = player.bench == .home ? "Home side" : "Away side"
                        HStack(spacing: Spacing.s12) {
                            Text("No. \(number)")
                                .font(TypeFace.body)
                                .foregroundStyle(Palette.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(side)
                                .font(TypeFace.callout)
                                .foregroundStyle(Palette.muted)
                            Button {
                                pending = player
                            } label: {
                                Image(systemName: "trash")
                                    .frame(minWidth: Hit.min, minHeight: Hit.min)
                            }
                            .buttonStyle(CapProminentStyle(role: .destructive))
                            .accessibilityLabel("Remove number \(number)")
                        }
                        .padding(.leading, Spacing.s12)
                        .hairlineCard()
                    }
                }
            }
            TextField("Number", text: $digits)
                .font(TypeFace.body)
                .keyboardType(.numberPad)
                .padding(Spacing.s12)
                .frame(minHeight: Hit.min)
                .hairlineChip()
                .focused($numberFocus)
                .onChange(of: digits) { _, new in
                    let clean = ScoreInput.digits(from: new)
                    if clean != new { digits = String(clean.prefix(2)) }
                }
            HStack(spacing: Spacing.s8) {
                Button("Home side") { away = false }
                    .buttonStyle(CapProminentStyle(role: away ? .secondary : .primary, expands: true))
                Button("Away side") { away = true }
                    .buttonStyle(CapProminentStyle(role: away ? .primary : .secondary, expands: true))
            }
            Button("Add number", action: add)
                .buttonStyle(CapProminentStyle(role: .primary, expands: true))
                .disabled(parsed == nil)
            if store.saveFault != nil {
                RetryBanner(title: "Save failed.") { Task { await store.flush() } }
            }
        }
        .navigationTitle("Roster")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsClose {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .frame(minHeight: Hit.min)
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { numberFocus = false }
                    .frame(minHeight: Hit.min)
            }
        }
        .confirmationDialog(
            removeTitle,
            isPresented: removePresented,
            titleVisibility: .visible
        ) {
            Button("Remove number", role: .destructive) {
                if let pending { store.removeRosterNumber(pending) }
                pending = nil
            }
            Button("Cancel", role: .cancel) { pending = nil }
        } message: {
            Text("New games will not include it. This game stays as it is.")
        }
    }

    private var removePresented: Binding<Bool> {
        Binding(
            get: { pending != nil },
            set: { shown in
                if shown == false { pending = nil }
            }
        )
    }

    private var parsed: Int? {
        guard let value = Int(digits), (1...99).contains(value) else { return nil }
        return value
    }

    private var removeTitle: String {
        if let pending {
            return "Remove number \(pending.number)?"
        }
        return "Remove number?"
    }

    private func add() {
        guard let number = parsed else { return }
        store.addRosterNumber(number, bench: away ? .away : .home)
        digits = ""
        numberFocus = false
    }
}
