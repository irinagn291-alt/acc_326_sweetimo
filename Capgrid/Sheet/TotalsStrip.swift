import SwiftUI

/// Home and away points. ViewThatFits keeps the figures intact when the row is narrow.
struct TotalsStrip: View {
    var homeName: String
    var awayName: String
    var home: TeamTotals
    var away: TeamTotals
    var canSeal: Bool
    var onSeal: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            sideBySide
            stacked
        }
        .padding(Spacing.s16)
        .hairlineCard()
    }

    private var sideBySide: some View {
        HStack(alignment: .center, spacing: Spacing.s16) {
            team(name: homeName, points: home.points, prominent: true)
            team(name: awayName, points: away.points, prominent: false)
            Spacer(minLength: Spacing.s8)
            seal
        }
    }

    private var stacked: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            team(name: homeName, points: home.points, prominent: true)
            team(name: awayName, points: away.points, prominent: false)
            seal
        }
    }

    private func team(name: String, points: Int, prominent: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text(name)
                .font(TypeFace.callout)
                .foregroundStyle(Palette.muted)
                .lineLimit(1)
                .truncationMode(.tail)
            PointsText(value: points, prominent: prominent)
        }
        .layoutPriority(prominent ? 1 : 0)
    }

    private var seal: some View {
        Button("Seal", action: onSeal)
            .buttonStyle(CapProminentStyle(role: .secondary))
            .disabled(canSeal == false)
            .frame(minWidth: Hit.min)
            .accessibilityHint("Freezes the caps for this game")
    }
}
