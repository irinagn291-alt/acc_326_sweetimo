import SwiftUI

/// Spacing, radii, elevation, and motion. Views read these accessors only.
enum Spacing {
    static let s4: CGFloat = 4
    static let s8: CGFloat = 8
    static let s12: CGFloat = 12
    static let s16: CGFloat = 16
    static let s20: CGFloat = 20
    static let s24: CGFloat = 24
    static let s32: CGFloat = 32
    static let s40: CGFloat = 40
    static let s48: CGFloat = 48
}

/// 44pt hits are the quality-bar minimum, not a spacing step.
enum Hit {
    static let min: CGFloat = 44
}

enum Radius {
    static let card: CGFloat = 12
    static let chip: CGFloat = 8
}

enum Elevation {
    static let hairline: CGFloat = 1
}

enum Palette {
    static let bg = DesignTokens.bg
    static let surface = DesignTokens.surface
    static let ink = DesignTokens.ink
    static let accent = DesignTokens.accent
    static let muted = DesignTokens.muted
}

enum Motion {
    static let duration: Double = 0.16
    static let pressScale: CGFloat = 0.97
    static let sheetScale: CGFloat = 0.96
    static let press = Animation.easeOut(duration: duration)
    static let spring = Animation.spring(duration: duration, bounce: 0)

    static var reviewFrozen: Bool {
        ProcessInfo.processInfo.arguments.contains(ReviewLaunch.argument)
    }
}

struct HairlineFill: ViewModifier {
    var corner: CGFloat

    func body(content: Content) -> some View {
        content
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Palette.muted, lineWidth: Elevation.hairline)
            )
    }
}

extension View {
    func hairlineCard() -> some View {
        modifier(HairlineFill(corner: Radius.card))
    }

    func hairlineChip() -> some View {
        modifier(HairlineFill(corner: Radius.chip))
    }
}
