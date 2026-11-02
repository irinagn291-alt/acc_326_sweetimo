import SwiftUI

/// Six steps. Didot is display and the points figure. Controls stay on the system body.
enum TypeFace {
    static var display: Font {
        .custom(DesignTokens.fontFamily, size: 64, relativeTo: .largeTitle)
    }

    static var figure: Font {
        .custom(DesignTokens.fontFamily, size: 48, relativeTo: .title)
    }

    static var title: Font {
        .system(.title3, design: .default, weight: .regular)
    }

    static var body: Font {
        .system(.body, design: .default, weight: .regular)
    }

    static var callout: Font {
        .system(.callout, design: .default, weight: .regular)
    }

    static var caption: Font {
        .system(.caption, design: .default, weight: .regular)
    }
}

struct DisplayWord: View {
    var word: String

    var body: some View {
        Text(word)
            .font(TypeFace.display)
            .foregroundStyle(Palette.ink)
            .tracking(-1)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

struct PointsText: View {
    var value: Int
    var prominent: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(value, format: .number.precision(.fractionLength(0)))
            .font(prominent ? TypeFace.figure : TypeFace.title)
            .monospacedDigit()
            .foregroundStyle(prominent ? Palette.accent : Palette.ink)
            .contentTransition(reduceMotion ? .opacity : .numericText(value: Double(value)))
            .animation(reduceMotion || Motion.reviewFrozen ? nil : Motion.spring, value: value)
            .fixedSize(horizontal: true, vertical: true)
    }
}
