import SwiftUI

struct ContentView: View {
    @Environment(SheetStore.self) private var store
    @State private var stage: Stage = .today
    @State private var deck: Deck?
    @State private var hookRead = false
    @State private var showSpinner = false

    var body: some View {
        Group {
            if store.isReady == false {
                skeleton
            } else if store.archive.onboardingComplete == false {
                OnboardingView(onFinish: {})
            } else {
                stageBody
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.bg.ignoresSafeArea())
        .overlay {
            if showSpinner && store.isReady == false {
                ProgressView("Loading the sheet.")
                    .padding(Spacing.s24)
                    .hairlineCard()
            }
        }
        .sheet(item: $deck) { item in
            deckBody(item)
                .sheetEntrance()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Palette.bg)
        }
        .transaction { transaction in
            if Motion.reviewFrozen {
                transaction.disablesAnimations = true
            }
        }
        .task { await armSpinner() }
        .onAppear(perform: consumeHook)
        .onChange(of: store.isReady) { _, _ in consumeHook() }
        .onChange(of: store.archive.onboardingComplete) { _, _ in consumeHook() }
    }

    @ViewBuilder
    private var stageBody: some View {
        switch stage {
        case .today:
            SheetView(deck: $deck)
        case .log:
            PlayTapeScreen()
        case .goals:
            GoalsScreen()
        case .matches:
            MatchesView()
        case .insights:
            InsightsView(onOpenMatches: { stage = .matches })
        case .settings:
            SettingsView(onReset: { stage = .today })
        case .twist:
            TwistScreen()
        case .roster:
            RosterScreen()
        }
    }

    @ViewBuilder
    private func deckBody(_ item: Deck) -> some View {
        switch item {
        case .matches:
            MatchesView(showsClose: true)
        case .insights:
            InsightsView(showsClose: true, onOpenMatches: { deck = .matches })
        case .settings:
            SettingsView(showsClose: true, onReset: { deck = nil })
        case .pad:
            JerseyPad { store.seatAndTag($0) }
                .modifier(CloseChrome(title: "Numbers", showsClose: true))
        case .onboarding:
            OnboardingView(onFinish: { deck = nil })
        case .tape:
            PlayTapeScreen(showsClose: true)
        case .goals:
            GoalsScreen(showsClose: true)
        case .twist:
            TwistScreen(showsClose: true)
        case .roster:
            RosterScreen(showsClose: true)
        }
    }

    private var skeleton: some View {
        VStack(alignment: .leading, spacing: Spacing.s16) {
            DisplayWord(word: "Sheet")
            Text("Number 23 tagged. Stamp a cap.")
                .font(TypeFace.body)
                .foregroundStyle(Palette.ink)
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Palette.surface)
                .frame(height: Spacing.s48 * 2)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .strokeBorder(Palette.muted, lineWidth: Elevation.hairline)
                )
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Palette.surface)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .strokeBorder(Palette.muted, lineWidth: Elevation.hairline)
                )
        }
        .padding(Spacing.s16)
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
    }

    private func armSpinner() async {
        try? await Task.sleep(for: .milliseconds(150))
        if store.isReady == false {
            showSpinner = true
        }
    }

    /// Read `-ReviewScreen` once, and only after onboarding is done.
    private func consumeHook() {
        guard store.isReady, store.archive.onboardingComplete, hookRead == false else { return }
        hookRead = true
        if let key = ReviewLaunch.screen {
            stage = Stage(reviewKey: key)
        }
    }
}

#Preview {
    ContentView()
        .environment(SheetStore())
}
