import SwiftUI
import UIKit

enum BoxScoreError: Error {
    case failed
}

/// One-page box drawn with UIGraphicsPDFRenderer. Totals come from the fold, not from typed overrides.
enum BoxScorePDF {
    /// Renders on the main actor, then writes the file off the main thread.
    static func write(fixture: Fixture, period: String) async throws -> URL {
        let data = await MainActor.run {
            render(fixture: fixture, period: period)
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("box-\(fixture.id.uuidString).pdf")
        do {
            try await Task.detached(priority: .userInitiated) {
                try data.write(to: url, options: .atomic)
            }.value
        } catch {
            throw BoxScoreError.failed
        }
        return url
    }

    static func render(fixture: Fixture, period: String) -> Data {
        let page = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        let sheet = Sheet(marks: fixture.marks)
        let lines = sheet.lines(roster: fixture.roster)
        let ink = UIColor(Palette.ink)
        let muted = UIColor(Palette.muted)
        return renderer.pdfData { context in
            context.beginPage()
            var y = Spacing.s48
            y = draw("Box", y: y, size: 36, didot: true, color: ink, page: page, context: context)
            y = draw(
                "\(fixture.home) and \(fixture.away)",
                y: y,
                size: 16,
                didot: false,
                color: ink,
                page: page,
                context: context
            )
            y = draw(period, y: y, size: 14, didot: false, color: muted, page: page, context: context)
            y = draw(
                scoreLine(fixture: fixture, sheet: sheet),
                y: y,
                size: 22,
                didot: true,
                color: ink,
                page: page,
                context: context
            )
            y += Spacing.s12
            for line in lines {
                if y > page.height - Spacing.s48 {
                    context.beginPage()
                    y = Spacing.s48
                }
                y = draw(
                    lineText(line),
                    y: y,
                    size: 14,
                    didot: false,
                    color: ink,
                    page: page,
                    context: context
                )
            }
        }
    }

    private static func scoreLine(fixture: Fixture, sheet: Sheet) -> String {
        let home = sheet.homeTotals.points.formatted(.number.precision(.fractionLength(0)))
        let away = sheet.awayTotals.points.formatted(.number.precision(.fractionLength(0)))
        return "\(fixture.home) \(home)   \(fixture.away) \(away)"
    }

    private static func lineText(_ line: JerseyLine) -> String {
        let number = line.jersey.number.formatted(.number.precision(.fractionLength(0)))
        let points = line.totals.points.formatted(.number.precision(.fractionLength(0)))
        let side = line.jersey.bench == .home ? "Home side" : "Away side"
        let boards = line.totals.rebound.formatted(.number.precision(.fractionLength(0)))
        return "\(number)  \(side)  \(points) pts  \(boards) rebounds"
    }

    private static func draw(
        _ text: String,
        y: CGFloat,
        size: CGFloat,
        didot: Bool,
        color: UIColor,
        page: CGRect,
        context: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        _ = context
        let font = (didot ? UIFont(name: DesignTokens.fontFamily, size: size) : nil)
            ?? UIFont.systemFont(ofSize: size)
        let width = page.width - Spacing.s48 * 2
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let attributed = NSAttributedString(string: text, attributes: attrs)
        let bounds = attributed.boundingRect(
            with: CGSize(width: width, height: 240),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let rect = CGRect(x: Spacing.s48, y: y, width: width, height: ceil(bounds.height) + Spacing.s4)
        attributed.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return rect.maxY + Spacing.s8
    }
}
