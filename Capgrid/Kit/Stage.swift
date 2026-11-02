import SwiftUI

/// Launch keys from `-ReviewScreen`. today, log, and goals are not tabs.
enum Stage: Equatable {
    case today
    case log
    case goals
    case matches
    case insights
    case settings
    case twist
    case roster

    init(reviewKey: String) {
        switch reviewKey {
        case "log", "playtape":
            self = .log
        case "goals":
            self = .goals
        case "matches":
            self = .matches
        case "insights":
            self = .insights
        case "settings":
            self = .settings
        case "twist":
            self = .twist
        case "roster":
            self = .roster
        default:
            self = .today
        }
    }
}

struct CloseChrome: ViewModifier {
    var title: String
    var showsClose: Bool
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if showsClose {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { dismiss() }
                                .frame(minHeight: Hit.min)
                        }
                    }
                }
        }
    }
}

enum Deck: String, Identifiable {
    case matches
    case insights
    case settings
    case pad
    case onboarding
    case tape
    case goals
    case twist
    case roster

    var id: String { rawValue }
}

enum DayKey {
    static func date(from key: Int, calendar: Calendar = .current) -> Date? {
        let year = key / 10000
        let month = (key / 100) % 100
        let day = key % 100
        guard year > 0, (1...12).contains(month), (1...31).contains(day) else { return nil }
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        parts.calendar = calendar
        parts.timeZone = calendar.timeZone
        return calendar.date(from: parts)
    }
}

enum ScoreInput {
    static func digits(from raw: String) -> String {
        let filtered = raw.filter(\.isNumber)
        return String(filtered.prefix(3))
    }

    static func value(from raw: String) -> Int? {
        let clean = digits(from: raw)
        guard clean.isEmpty == false else { return nil }
        return Int(clean)
    }
}
