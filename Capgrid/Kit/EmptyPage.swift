import SwiftUI

/// Full-page empty state. Art, one headline, one line, one bottom action.
struct EmptyPage: View {
    var imageName: String
    var title: String
    var line: String
    var actionTitle: String
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s16) {
            DisplayWord(word: title)
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: Spacing.s48 * 4)
                .clipped()
                .accessibilityHidden(true)
            Text(line)
                .font(TypeFace.body)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Spacing.s24)
            Button(actionTitle, action: action)
                .buttonStyle(CapProminentStyle(expands: true))
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.bg.ignoresSafeArea())
    }
}

struct RetryBanner: View {
    var title: String
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text(title)
                .font(TypeFace.body)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Button("Try again", action: action)
                .buttonStyle(CapProminentStyle(role: .secondary, expands: true))
        }
        .padding(Spacing.s16)
        .hairlineCard()
    }
}

struct ScreenScroll<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s16) {
                    content()
                }
                .padding(.horizontal, Spacing.s16)
                .padding(.top, Spacing.s8)
                .padding(.bottom, Spacing.s32)
                .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .topLeading)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .background(Palette.bg.ignoresSafeArea())
    }
}
