import Foundation

/// Stat kinds a volunteer stamps on the cap grid.
/// Points are derived: made two is 2, made three is 3, free throw is 1. Other kinds score 0.
enum StatKind: String, Codable, Sendable, CaseIterable, Hashable {
    case madeTwo
    case madeThree
    case freeThrow
    case rebound
    case assist
    case steal
    case block
    case foul
    case turnover

    var points: Int {
        switch self {
        case .madeTwo: 2
        case .madeThree: 3
        case .freeThrow: 1
        case .rebound, .assist, .steal, .block, .foul, .turnover: 0
        }
    }

    /// Short chip shown while a cap is held. UI reads this; it is not a stored total.
    var chip: String {
        switch self {
        case .madeTwo: "+2"
        case .madeThree: "+3"
        case .freeThrow: "+1"
        case .rebound: "REB"
        case .assist: "AST"
        case .steal: "STL"
        case .block: "BLK"
        case .foul: "FOUL"
        case .turnover: "TO"
        }
    }
}
