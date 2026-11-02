import SwiftUI

extension StatKind {
    var title: String {
        switch self {
        case .madeTwo: "Made two"
        case .madeThree: "Made three"
        case .freeThrow: "Free throw"
        case .rebound: "Rebound"
        case .assist: "Assist"
        case .steal: "Steal"
        case .block: "Block"
        case .foul: "Foul"
        case .turnover: "Turnover"
        }
    }

    var pointsVerb: Bool {
        switch self {
        case .madeTwo, .madeThree, .freeThrow: true
        default: false
        }
    }
}

private struct ButtonSizeKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

/// One stat cap. Press previews the chip. Release inside stamps. Dragging off cancels.
struct CapButton: View {
    var cap: Cap
    var prominent: Bool
    var enabled: Bool
    var onFlight: (Bool) -> Void
    var onStamp: () -> Void

    @GestureState private var flight = false
    @State private var bounds: CGSize = .zero

    var body: some View {
        Button(action: onStamp) {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                Text(cap.kind.chip)
                    .font(TypeFace.callout)
                    .foregroundStyle(prominent && enabled ? Palette.surface : Palette.muted)
                Text(cap.kind.title)
                    .font(TypeFace.body)
                    .foregroundStyle(prominent && enabled ? Palette.surface : Palette.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(cap.stamped, format: .number.precision(.fractionLength(0)))
                    .font(TypeFace.title)
                    .monospacedDigit()
                    .foregroundStyle(prominent && enabled ? Palette.surface : Palette.ink)
                    .contentTransition(.numericText(value: Double(cap.stamped)))
                    .animation(Motion.spring, value: cap.stamped)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Spacing.s12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .frame(minHeight: Spacing.s48 * 2)
        }
        .buttonStyle(CapProminentStyle(role: prominent && enabled ? .primary : .secondary, expands: true))
        .disabled(enabled == false)
        .accessibilityLabel("\(cap.kind.title), \(cap.stamped.formatted(.number.precision(.fractionLength(0)))) stamped")
        .background {
            GeometryReader { proxy in
                Color.clear.preference(key: ButtonSizeKey.self, value: proxy.size)
            }
        }
        .onPreferenceChange(ButtonSizeKey.self) { bounds = $0 }
        .simultaneousGesture(hold)
        .onChange(of: flight) { _, active in
            onFlight(active)
        }
    }

    private var hold: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .updating($flight) { value, state, _ in
                state = enabled && contains(value.location)
            }
    }

    private func contains(_ location: CGPoint) -> Bool {
        guard bounds.width > 1, bounds.height > 1 else { return true }
        return location.x >= 0
            && location.y >= 0
            && location.x <= bounds.width
            && location.y <= bounds.height
    }
}
