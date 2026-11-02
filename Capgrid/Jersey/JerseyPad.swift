import SwiftUI

/// Number pad for a player who is not already on the rail.
struct JerseyPad: View {
    var onTag: (Jersey) -> Void

    @State private var digits = ""
    @State private var away = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScreenScroll {
            DisplayWord(word: "Number")
            Text(prompt)
                .font(TypeFace.body)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Group {
                if let value = Int(digits) {
                    Text(value, format: .number.precision(.fractionLength(0)))
                        .contentTransition(.numericText(value: Double(value)))
                } else {
                    Text(" ")
                }
            }
            .font(TypeFace.figure)
            .monospacedDigit()
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity, minHeight: Hit.min, alignment: .leading)
            sidePicker
            keys
            Button("Tag number", action: commit)
                .buttonStyle(CapProminentStyle(expands: true))
                .disabled(parsed == nil)
        }
        .navigationTitle("Numbers")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var prompt: String {
        parsed == nil
            ? "Enter a number from 1 to 99, then tag it."
            : "Ready. Tag this number, then stamp a cap."
    }

    private var parsed: Int? {
        guard let value = Int(digits), (1...99).contains(value) else { return nil }
        return value
    }

    private var sidePicker: some View {
        HStack(spacing: Spacing.s8) {
            Button("Home side") { away = false }
                .buttonStyle(CapProminentStyle(role: away ? .secondary : .primary, expands: true))
            Button("Away side") { away = true }
                .buttonStyle(CapProminentStyle(role: away ? .primary : .secondary, expands: true))
        }
    }

    private var keys: some View {
        VStack(spacing: Spacing.s8) {
            row([1, 2, 3])
            row([4, 5, 6])
            row([7, 8, 9])
            HStack(spacing: Spacing.s8) {
                Color.clear.frame(maxWidth: .infinity, minHeight: Hit.min).accessibilityHidden(true)
                digitButton(0)
                Button(action: backspace) {
                    Image(systemName: "delete.left")
                        .frame(maxWidth: .infinity, minHeight: Hit.min)
                }
        .buttonStyle(CapProminentStyle(role: .secondary, expands: true))
        .accessibilityLabel("Delete digit")
            }
        }
    }

    private func row(_ values: [Int]) -> some View {
        HStack(spacing: Spacing.s8) {
            ForEach(values, id: \.self) { value in
                digitButton(value)
            }
        }
    }

    private func digitButton(_ value: Int) -> some View {
        Button {
            guard digits.count < 2 else { return }
            digits.append(String(value))
        } label: {
            Text(value, format: .number.precision(.fractionLength(0)))
                .frame(maxWidth: .infinity, minHeight: Hit.min)
        }
        .buttonStyle(CapProminentStyle(role: .secondary, expands: true))
    }

    private func backspace() {
        if digits.isEmpty == false { digits.removeLast() }
    }

    private func commit() {
        guard let number = parsed else { return }
        onTag(Jersey(number: number, bench: away ? .away : .home))
        dismiss()
    }
}
