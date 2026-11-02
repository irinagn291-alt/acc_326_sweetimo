import SwiftUI

/// Period, numbers, contact, and reset. Everything stays on this phone.
struct SettingsView: View {
    var showsClose: Bool = false
    var onReset: () -> Void = {}
    @Environment(SheetStore.self) private var store
    @State private var period = ""
    @State private var replay = false
    @State private var showRule = false
    @State private var confirmReset = false
    @State private var resetting = false
    @FocusState private var field: Field?

    private enum Field: Hashable {
        case period
    }

    private let periods = ["8 min quarters", "10 min quarters", "12 min halves"]

    var body: some View {
        ScreenScroll {
            DisplayWord(word: "Settings")
            Text("All data stays on this phone.")
                .font(TypeFace.body)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            periodBlock
            rosterBlock
            contactBlock
            Button("Show the intro") { replay = true }
                .buttonStyle(CapProminentStyle(role: .secondary, expands: true))
            Button("How a cap counts") { showRule = true }
                .buttonStyle(CapProminentStyle(role: .secondary, expands: true))
            Button("Reset all data") { confirmReset = true }
                .buttonStyle(CapProminentStyle(role: .destructive, expands: true))
                .disabled(resetting)
            if store.saveFault != nil {
                RetryBanner(title: "Save failed.") { Task { await store.flush() } }
            }
        }
        .modifier(CloseChrome(title: "Settings", showsClose: showsClose))
        .onAppear { period = store.archive.periodLengthLabel }
        .onChange(of: period) { _, new in
            store.updatePeriodLength(new)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { field = nil }
                    .frame(minHeight: Hit.min)
            }
        }
        .sheet(isPresented: $replay) {
            OnboardingView(onFinish: { replay = false })
                .presentationDetents([.large])
                .presentationBackground(Palette.bg)
                .sheetEntrance()
        }
        .sheet(isPresented: $showRule) {
            TwistScreen(showsClose: true)
                .presentationDetents([.large])
                .presentationBackground(Palette.bg)
                .sheetEntrance()
        }
        .confirmationDialog(
            "Reset all data?",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Reset all data", role: .destructive) { wipe() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes every game on this phone.")
        }
    }

    private var periodBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("Period length")
                .font(TypeFace.title)
                .foregroundStyle(Palette.ink)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.s8) {
                    periodChoices
                }
                VStack(alignment: .leading, spacing: Spacing.s8) {
                    periodChoices
                }
            }
            TextField("Period length", text: $period)
                .font(TypeFace.body)
                .padding(Spacing.s12)
                .frame(minHeight: Hit.min)
                .hairlineChip()
                .focused($field, equals: .period)
                .submitLabel(.done)
                .onSubmit { field = nil }
        }
        .padding(Spacing.s16)
        .hairlineCard()
    }

    @ViewBuilder
    private var periodChoices: some View {
        ForEach(periods, id: \.self) { label in
            Button(label) { period = label }
                .buttonStyle(CapProminentStyle(
                    role: period == label ? .primary : .secondary,
                    expands: true
                ))
        }
    }

    private var rosterBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("Numbers")
                .font(TypeFace.title)
                .foregroundStyle(Palette.ink)
            if store.archive.roster.isEmpty {
                Text("No numbers yet.")
                    .font(TypeFace.body)
                    .foregroundStyle(Palette.ink)
            } else {
                Text(rosterLine)
                    .font(TypeFace.body)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            NavigationLink {
                RosterScreen()
            } label: {
                Text("Edit numbers")
                    .font(TypeFace.body)
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, minHeight: Hit.min)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                            .strokeBorder(Palette.muted, lineWidth: Elevation.hairline)
                    )
            }
            .accessibilityHint("Opens the number list")
        }
        .padding(Spacing.s16)
        .hairlineCard()
    }

    private var rosterLine: String {
        store.archive.roster
            .map { $0.number.formatted(.number.precision(.fractionLength(0))) }
            .joined(separator: ", ")
    }

    private var contactBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("Contact")
                .font(TypeFace.title)
                .foregroundStyle(Palette.ink)
            if let url = URL(string: "https://capgrid-sheet.online/contact-us") {
                Link(destination: url) {
                    Label("Contact", systemImage: "envelope")
                        .font(TypeFace.body)
                        .foregroundStyle(Palette.ink)
                        .frame(maxWidth: .infinity, minHeight: Hit.min)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                                .strokeBorder(Palette.muted, lineWidth: Elevation.hairline)
                        )
                }
            }
        }
        .padding(Spacing.s16)
        .hairlineCard()
    }

    private func wipe() {
        guard resetting == false else { return }
        resetting = true
        Task {
            await store.resetAllData()
            resetting = false
            onReset()
        }
    }
}
