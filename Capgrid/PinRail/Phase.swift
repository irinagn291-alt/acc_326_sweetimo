import Foundation

/// Pin-rail phase ADT. Open has no seated jersey. Tagged holds exactly one Jersey.
/// Tag folds Open to Tagged. Cap folds Tagged back to Open. The phase is never edited by hand.
enum Phase: Hashable, Sendable {
    case open
    case tagged(Jersey)
}

extension Phase: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind
        case jersey
    }

    private enum Kind: String, Codable {
        case open
        case tagged
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .open:
            self = .open
        case .tagged:
            let jersey = try container.decode(Jersey.self, forKey: .jersey)
            self = .tagged(jersey)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .open:
            try container.encode(Kind.open, forKey: .kind)
        case .tagged(let jersey):
            try container.encode(Kind.tagged, forKey: .kind)
            try container.encode(jersey, forKey: .jersey)
        }
    }
}
