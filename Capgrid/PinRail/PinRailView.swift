import SwiftUI

/// Pin rail. One number is tagged. The preview chip sits on that number while a cap is held.
struct PinRailView: View {
    var roster: [Jersey]
    var phase: Phase
    var flightChip: String?
    var onTag: (Jersey) -> Void
    var onPad: (() -> Void)? = nil

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: Spacing.s8) {
                ForEach(roster) { jersey in
                    chip(jersey)
                }
                if let onPad {
                    Button(action: onPad) {
                        Image(systemName: "plus")
                            .font(TypeFace.body)
                            .foregroundStyle(Palette.ink)
                            .frame(minWidth: Hit.min, minHeight: Hit.min)
                            .padding(.horizontal, Spacing.s8)
                    }
                    .buttonStyle(CapProminentStyle(role: .secondary))
                    .accessibilityLabel("Add a number")
                }
            }
            .padding(.vertical, Spacing.s4)
        }
        .scrollIndicators(.hidden)
    }

    private func chip(_ jersey: Jersey) -> some View {
        let tagged = isTagged(jersey)
        return Button {
            onTag(jersey)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                Text(jersey.number, format: .number.precision(.fractionLength(0)))
                    .font(TypeFace.title)
                    .monospacedDigit()
                    .foregroundStyle(tagged ? Palette.surface : Palette.ink)
                Text(flightChip == nil || tagged == false ? " " : (flightChip ?? " "))
                    .font(TypeFace.caption)
                    .foregroundStyle(Palette.surface)
                    .opacity(tagged && flightChip != nil ? 1 : 0)
                    .lineLimit(1)
            }
            .padding(.horizontal, Spacing.s12)
            .padding(.vertical, Spacing.s8)
            .frame(minWidth: Hit.min, minHeight: Hit.min, alignment: .leading)
        }
        .buttonStyle(CapProminentStyle(role: tagged ? .primary : .secondary))
        .accessibilityLabel(tagged ? "Number \(jersey.number) tagged" : "Tag number \(jersey.number)")
    }

    private func isTagged(_ jersey: Jersey) -> Bool {
        if case .tagged(let seated) = phase {
            return seated.id == jersey.id
        }
        return false
    }
}
