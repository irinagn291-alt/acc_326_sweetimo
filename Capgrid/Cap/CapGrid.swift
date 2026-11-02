import SwiftUI

/// Column grid. `GridLayout` has no column count, so this layout places 3 or 4 columns
/// and `AnyLayout` swaps them for compact and regular width.
struct CapGridLayout: Layout {
    var columns: Int
    var gap: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let natural = naturalHeight(width: width, subviews: subviews)
        let proposed = proposal.height ?? natural
        let height = proposed.isFinite ? max(natural, proposed) : natural
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard columns > 0, subviews.isEmpty == false else { return }
        let width = bounds.width
        let cellWidth = (width - gap * CGFloat(columns - 1)) / CGFloat(max(columns, 1))
        let rows = rowCount(subviews.count)
        let natural = naturalHeight(width: width, subviews: subviews)
        let extra = max(0, bounds.height - natural)
        let rowHeight = baseRowHeight(width: width, subviews: subviews) + extra / CGFloat(rows)
        let cellProposal = ProposedViewSize(width: max(cellWidth, 0), height: rowHeight)
        var index = 0
        for subview in subviews {
            let row = index / columns
            let column = index % columns
            let x = bounds.minX + CGFloat(column) * (cellWidth + gap)
            let y = bounds.minY + CGFloat(row) * (rowHeight + gap)
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: cellProposal)
            index += 1
        }
    }

    private func rowCount(_ count: Int) -> Int {
        max(1, Int(ceil(Double(count) / Double(max(columns, 1)))))
    }

    private func baseRowHeight(width: CGFloat, subviews: Subviews) -> CGFloat {
        let cellWidth = (width - gap * CGFloat(columns - 1)) / CGFloat(max(columns, 1))
        let proposal = ProposedViewSize(width: max(cellWidth, 0), height: nil)
        var tallest: CGFloat = Spacing.s48 * 2
        for subview in subviews {
            tallest = max(tallest, subview.sizeThatFits(proposal).height)
        }
        return tallest
    }

    private func naturalHeight(width: CGFloat, subviews: Subviews) -> CGFloat {
        guard subviews.isEmpty == false else { return 0 }
        let rows = rowCount(subviews.count)
        let rowHeight = baseRowHeight(width: width, subviews: subviews)
        return CGFloat(rows) * rowHeight + CGFloat(rows - 1) * gap
    }
}

/// Cap keypad. Regular width is four columns. Compact width is three.
struct CapGrid: View {
    var caps: [Cap]
    /// True while a number is tagged and the sheet can accept a cap.
    var capsLive: Bool
    /// False after seal. Keys stay visible and do not accept taps.
    var interactive: Bool
    var flight: StatKind?
    var onFlight: (StatKind?) -> Void
    var onStamp: (StatKind) -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass

    private var columns: Int {
        sizeClass == .regular ? 4 : 3
    }

    var body: some View {
        let grid = GridLayout(
            alignment: .leading,
            horizontalSpacing: Spacing.s12,
            verticalSpacing: Spacing.s12
        )
        let gap = grid.horizontalSpacing ?? Spacing.s12
        AnyLayout(CapGridLayout(columns: columns, gap: gap)) {
            ForEach(caps) { cap in
                CapButton(
                    cap: cap,
                    prominent: cap.kind.pointsVerb && capsLive,
                    enabled: interactive,
                    onFlight: { active in
                        if active {
                            onFlight(cap.kind)
                        } else if flight == cap.kind {
                            onFlight(nil)
                        }
                    },
                    onStamp: { onStamp(cap.kind) }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
