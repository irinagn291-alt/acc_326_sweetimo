import Foundation

/// Ordered log the sheet folds. Totals are never a case here.
enum SheetMark: Hashable, Codable, Sendable {
    case tag(TagMark)
    case cap(CapMark)
    case bare(BareMark)
    case peel(PeelMark)
    case seal(SealMark)

    private enum CodingKeys: String, CodingKey {
        case kind
        case tag
        case cap
        case bare
        case peel
        case seal
    }

    private enum Kind: String, Codable {
        case tag
        case cap
        case bare
        case peel
        case seal
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .tag:
            self = .tag(try container.decode(TagMark.self, forKey: .tag))
        case .cap:
            self = .cap(try container.decode(CapMark.self, forKey: .cap))
        case .bare:
            self = .bare(try container.decode(BareMark.self, forKey: .bare))
        case .peel:
            self = .peel(try container.decode(PeelMark.self, forKey: .peel))
        case .seal:
            self = .seal(try container.decode(SealMark.self, forKey: .seal))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .tag(let mark):
            try container.encode(Kind.tag, forKey: .kind)
            try container.encode(mark, forKey: .tag)
        case .cap(let mark):
            try container.encode(Kind.cap, forKey: .kind)
            try container.encode(mark, forKey: .cap)
        case .bare(let mark):
            try container.encode(Kind.bare, forKey: .kind)
            try container.encode(mark, forKey: .bare)
        case .peel(let mark):
            try container.encode(Kind.peel, forKey: .kind)
            try container.encode(mark, forKey: .peel)
        case .seal(let mark):
            try container.encode(Kind.seal, forKey: .kind)
            try container.encode(mark, forKey: .seal)
        }
    }
}
