import Foundation

/// One root record. Fixtures, the default roster, the current phase, and each fixture's marks.
/// Totals are absent on purpose: they are recomputed from CapMarks on load.
struct SheetArchive: Codable, Sendable, Equatable {
    static let schema = 1

    var schemaVersion: Int
    var fixtures: [Fixture]
    var roster: [Jersey]
    var phase: Phase
    var activeFixtureID: UUID?
    var onboardingComplete: Bool
    var periodLengthLabel: String

    init(
        schemaVersion: Int = SheetArchive.schema,
        fixtures: [Fixture] = [],
        roster: [Jersey] = [],
        phase: Phase = .open,
        activeFixtureID: UUID? = nil,
        onboardingComplete: Bool = false,
        periodLengthLabel: String = "8 min quarters"
    ) {
        self.schemaVersion = schemaVersion
        self.fixtures = fixtures
        self.roster = roster
        self.phase = phase
        self.activeFixtureID = activeFixtureID
        self.onboardingComplete = onboardingComplete
        self.periodLengthLabel = periodLengthLabel
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .schemaVersion)
        switch version {
        case SheetArchive.schema:
            schemaVersion = version
            fixtures = try container.decode([Fixture].self, forKey: .fixtures)
            roster = try container.decode([Jersey].self, forKey: .roster)
            phase = try container.decode(Phase.self, forKey: .phase)
            activeFixtureID = try container.decodeIfPresent(UUID.self, forKey: .activeFixtureID)
            onboardingComplete = try container.decode(Bool.self, forKey: .onboardingComplete)
            periodLengthLabel = try container.decode(String.self, forKey: .periodLengthLabel)
        default:
            throw ArchiveError.unknownSchema(version)
        }
    }

    /// Phase stored in the file is a projection. The fold of the active fixture wins.
    func reconciled() -> SheetArchive {
        var copy = self
        guard let id = activeFixtureID, let fixture = fixtures.first(where: { $0.id == id }) else {
            copy.phase = .open
            return copy
        }
        switch fixture.face() {
        case .blank:
            copy.phase = .open
        case .sheet(let sheet):
            copy.phase = sheet.phase
        }
        return copy
    }

    var activeFixture: Fixture? {
        guard let activeFixtureID else { return nil }
        return fixtures.first { $0.id == activeFixtureID }
    }
}

enum ArchiveError: Error, Equatable {
    case unknownSchema(Int)
}

enum ArchiveCoding {
    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }

    static func encode(_ archive: SheetArchive) throws -> Data {
        try encoder().encode(archive)
    }

    static func decode(_ data: Data) throws -> SheetArchive {
        try decoder().decode(SheetArchive.self, from: data).reconciled()
    }
}
