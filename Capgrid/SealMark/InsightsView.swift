import SwiftUI

/// The box after the stamps. Export is there once the game is sealed.
struct InsightsView: View {
    var showsClose: Bool = false
    var onOpenMatches: () -> Void = {}
    @Environment(SheetStore.self) private var store
    @State private var confirmSeal = false
    @State private var exporting = false
    @State private var exportURL: URL?
    @State private var exportFailed = false

    var body: some View {
        Group {
            if store.archive.activeFixture == nil {
                EmptyPage(
                    imageName: "cgr_SealedBox",
                    title: "Box",
                    line: "No game yet. Add the teams, then stamp the caps.",
                    actionTitle: "Add a game",
                    action: onOpenMatches
                )
            } else {
                ScreenScroll {
                    DisplayWord(word: "Box")
                    filled
                }
            }
        }
        .modifier(CloseChrome(title: "Box", showsClose: showsClose))
        .confirmationDialog("Seal this game?", isPresented: $confirmSeal, titleVisibility: .visible) {
            Button("Seal") { store.seal() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Caps stay as they are. Then you can export the box.")
        }
    }

    @ViewBuilder
    private var filled: some View {
        if let fixture = store.archive.activeFixture {
            HStack(alignment: .center, spacing: Spacing.s16) {
                Image("cgr_SealedBox")
                    .resizable()
                    .scaledToFit()
                    .frame(width: Spacing.s48 * 2, height: Spacing.s48 * 2)
                    .clipped()
                    .accessibilityHidden(true)
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
                    Text(fixture.sealed == nil ? "Still live." : "Sealed.")
                        .font(TypeFace.callout)
                        .foregroundStyle(Palette.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                PointsText(value: store.homeTotals.points, prominent: true)
            }
            .padding(Spacing.s16)
            .hairlineCard()

            if store.jerseyLines.isEmpty {
                Text("No caps yet. Tag a number on the sheet, then stamp.")
                    .font(TypeFace.body)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: Spacing.s8) {
                    ForEach(store.jerseyLines) { line in
                        let number = line.jersey.number.formatted(.number.precision(.fractionLength(0)))
                        let side = line.jersey.bench == .home ? "Home side" : "Away side"
                        HStack(spacing: Spacing.s12) {
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
                                .font(TypeFace.body)
                                .monospacedDigit()
                                .foregroundStyle(Palette.ink)
                                .layoutPriority(1)
                        }
                        .padding(Spacing.s12)
                        .hairlineCard()
                    }
                }
            }

            if fixture.sealed == nil {
                Text("Seal the game, then export.")
                    .font(TypeFace.body)
                    .foregroundStyle(Palette.ink)
                Button("Seal") { confirmSeal = true }
                    .buttonStyle(CapProminentStyle(role: .secondary, expands: true))
            } else {
                Button(action: export) {
                    if exporting {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: Hit.min)
                    } else {
                        Text("Export PDF")
                    }
                }
                .buttonStyle(CapProminentStyle(role: .primary, expands: true))
                .disabled(exporting)
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label("Share PDF", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity, minHeight: Hit.min)
                    }
                    .buttonStyle(CapProminentStyle(role: .secondary, expands: true))
                }
            }
            if exportFailed {
                RetryBanner(title: "Export failed.") { export() }
            }
            if store.saveFault != nil {
                RetryBanner(title: "Save failed.") { Task { await store.flush() } }
            }
        }
    }

    private func export() {
        guard exporting == false, let fixture = store.archive.activeFixture, fixture.sealed != nil else { return }
        exporting = true
        exportFailed = false
        let period = store.archive.periodLengthLabel
        Task { @MainActor in
            defer { exporting = false }
            do {
                exportURL = try await BoxScorePDF.write(fixture: fixture, period: period)
            } catch {
                exportURL = nil
                exportFailed = true
            }
        }
    }
}
