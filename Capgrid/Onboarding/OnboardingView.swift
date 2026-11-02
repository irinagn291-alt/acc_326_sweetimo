import SwiftUI

/// Three pages. Continue sits at the bottom. Skip writes the same defaults.
struct OnboardingView: View {
    var onFinish: () -> Void
    @Environment(SheetStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [(image: String, word: String, line: String)] = [
        ("cgr_Onboarding1", "Sheet", "Tag a number, then stamp the stat. Totals add themselves."),
        ("cgr_Onboarding2", "Stamp", "Hold a cap to see it, then release to count it."),
        ("cgr_Onboarding3", "Box", "Seal the game and share the box when play stops.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s16) {
            pageBody
                .id(page)
                .transition(.opacity)
            Spacer(minLength: Spacing.s16)
            Button("Skip", action: finish)
                .buttonStyle(CapProminentStyle(role: .secondary, expands: true))
            Button("Continue", action: advance)
                .buttonStyle(CapProminentStyle(role: .primary, expands: true))
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.bg.ignoresSafeArea())
    }

    private var pageBody: some View {
        VStack(alignment: .leading, spacing: Spacing.s16) {
            DisplayWord(word: pages[page].word)
            Text(step)
                .font(TypeFace.caption)
                .foregroundStyle(Palette.muted)
            Image(pages[page].image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: Spacing.s48 * 5)
                .clipped()
                .accessibilityHidden(true)
            Text(pages[page].line)
                .font(TypeFace.body)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var step: String {
        let current = (page + 1).formatted(.number.precision(.fractionLength(0)))
        let total = pages.count.formatted(.number.precision(.fractionLength(0)))
        return "\(current) of \(total)"
    }

    private func advance() {
        if page + 1 < pages.count {
            if Motion.reviewFrozen {
                page += 1
            } else if reduceMotion {
                withAnimation(.easeOut(duration: Motion.duration)) { page += 1 }
            } else {
                withAnimation(Motion.press) { page += 1 }
            }
        } else {
            finish()
        }
    }

    private func finish() {
        store.completeOnboarding()
        onFinish()
    }
}
