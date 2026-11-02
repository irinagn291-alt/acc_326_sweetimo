import SwiftUI

/// Filled, bordered primary. Press scales to 0.97. Reduce Motion fades instead.
struct CapProminentStyle: ButtonStyle {
    enum Role {
        case primary
        case secondary
        case destructive
    }

    var role: Role = .primary
    var expands: Bool = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && isEnabled
        configuration.label
            .font(TypeFace.body)
            .foregroundStyle(foreground)
            .padding(.horizontal, Spacing.s16)
            .padding(.vertical, Spacing.s12)
            .frame(
                maxWidth: expands ? .infinity : nil,
                minHeight: Hit.min,
                maxHeight: expands ? .infinity : nil
            )
            .background(fill, in: RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                    .strokeBorder(border, lineWidth: Elevation.hairline)
            )
            .scaleEffect(reduceMotion || pressed == false ? 1 : Motion.pressScale)
            .opacity(pressed && reduceMotion ? 0.72 : (isEnabled ? 1 : 0.45))
            .animation(reduceMotion ? .easeOut(duration: Motion.duration) : Motion.press, value: pressed)
            .contentShape(RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
    }

    private var fill: Color {
        guard isEnabled else { return Palette.muted.opacity(0.28) }
        switch role {
        case .primary: return Palette.accent
        case .secondary, .destructive: return Palette.surface
        }
    }

    private var foreground: Color {
        guard isEnabled else { return Palette.ink }
        switch role {
        case .primary: return Palette.surface
        case .secondary, .destructive: return Palette.ink
        }
    }

    private var border: Color {
        switch role {
        case .primary: return isEnabled ? Palette.accent : Palette.muted
        case .secondary, .destructive: return Palette.muted
        }
    }
}

struct SheetEntrance: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .scaleEffect(reduceMotion || shown ? 1 : Motion.sheetScale)
            .onAppear {
                guard Motion.reviewFrozen == false else {
                    shown = true
                    return
                }
                if reduceMotion {
                    withAnimation(.easeOut(duration: Motion.duration)) { shown = true }
                } else {
                    withAnimation(Motion.press) { shown = true }
                }
            }
    }
}

extension View {
    func sheetEntrance() -> some View {
        modifier(SheetEntrance())
    }
}
