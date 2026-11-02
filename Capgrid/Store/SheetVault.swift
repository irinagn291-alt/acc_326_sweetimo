import Foundation

/// Seam between the in-memory archive and storage.
/// The file in Application Support is the source that survives a force-quit.
/// The same JSON is also stored under `cgr.archive.v1` so the single UserDefaults key stays in step.
/// The UI never calls this type. SheetStore does.
actor SheetVault {
    static let archiveKey = "cgr.archive.v1"
    static let demoKey = "cgr.demo.v1"
    static let fileName = "sheet-archive.json"

    private let directory: URL
    private let defaults: UserDefaults
    private let fileManager: FileManager

    init(directory: URL, defaults: UserDefaults = .standard, fileManager: FileManager = .default) {
        self.directory = directory
        self.defaults = defaults
        self.fileManager = fileManager
    }

    /// Isolated suite for tests. The suite name is wiped before the first read.
    init(directory: URL, suiteName: String, fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
        let suite = UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
        suite.removePersistentDomain(forName: suiteName)
        self.defaults = suite
    }

    static func applicationSupport() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base.appendingPathComponent("Sweetimo", isDirectory: true)
    }

    private var fileURL: URL { directory.appendingPathComponent(Self.fileName) }
    private var backupURL: URL { directory.appendingPathComponent(Self.fileName + ".backup") }

    func load() -> ArchiveLoad {
        prepareDirectory()
        if let data = read(fileURL), let archive = tryDecode(data) {
            return ArchiveLoad(archive: archive, notice: nil, usedBackup: false)
        }
        if fileManager.fileExists(atPath: fileURL.path), let data = read(backupURL), let archive = tryDecode(data) {
            return ArchiveLoad(
                archive: archive,
                notice: "Restored the previous box score.",
                usedBackup: true
            )
        }
        if let stored = defaults.data(forKey: Self.archiveKey), let archive = tryDecode(stored) {
            return ArchiveLoad(archive: archive, notice: nil, usedBackup: false)
        }
        if fileManager.fileExists(atPath: fileURL.path) || defaults.data(forKey: Self.archiveKey) != nil {
            return ArchiveLoad(
                archive: SheetArchive(),
                notice: "The box score file was unreadable. Started a fresh sheet.",
                usedBackup: false
            )
        }
        return ArchiveLoad(archive: SheetArchive(), notice: nil, usedBackup: false)
    }

    /// Atomic write. A failed write leaves the previous file in place and reports the fault.
    func save(_ archive: SheetArchive) -> ArchiveFault? {
        prepareDirectory()
        let payload: Data
        do {
            payload = try ArchiveCoding.encode(archive.reconciled())
        } catch {
            return .writeFailed
        }
        if let current = read(fileURL), tryDecode(current) != nil {
            do {
                if fileManager.fileExists(atPath: backupURL.path) {
                    try fileManager.removeItem(at: backupURL)
                }
                try fileManager.copyItem(at: fileURL, to: backupURL)
            } catch {
                return .writeFailed
            }
        }
        let temporary = directory.appendingPathComponent("sheet-archive-\(UUID().uuidString).tmp")
        do {
            try payload.write(to: temporary, options: .atomic)
            if fileManager.fileExists(atPath: fileURL.path) {
                _ = try fileManager.replaceItemAt(fileURL, withItemAt: temporary)
            } else {
                try fileManager.moveItem(at: temporary, to: fileURL)
            }
            defaults.set(payload, forKey: Self.archiveKey)
            return nil
        } catch {
            try? fileManager.removeItem(at: temporary)
            return .writeFailed
        }
    }

    func reset() -> ArchiveFault? {
        prepareDirectory()
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                return .writeFailed
            }
        }
        if fileManager.fileExists(atPath: backupURL.path) {
            do {
                try fileManager.removeItem(at: backupURL)
            } catch {
                return .writeFailed
            }
        }
        defaults.removeObject(forKey: Self.archiveKey)
        return nil
    }

    func demoAlreadyApplied() -> Bool {
        defaults.bool(forKey: Self.demoKey)
    }

    func markDemoApplied() {
        defaults.set(true, forKey: Self.demoKey)
    }

    /// Test seam for a corrupt UserDefaults mirror. Production writes go through `save`.
    func setMirroredArchive(_ data: Data?) {
        if let data {
            defaults.set(data, forKey: Self.archiveKey)
        } else {
            defaults.removeObject(forKey: Self.archiveKey)
        }
    }

    func mirroredArchive() -> Data? {
        defaults.data(forKey: Self.archiveKey)
    }

    private func prepareDirectory() {
        if fileManager.fileExists(atPath: directory.path) == false {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        var values = URLResourceValues()
        values.isExcludedFromBackup = false
        var url = directory
        try? url.setResourceValues(values)
    }

    private func read(_ url: URL) -> Data? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return try? Data(contentsOf: url)
    }

    private func tryDecode(_ data: Data) -> SheetArchive? {
        try? ArchiveCoding.decode(data)
    }
}

struct ArchiveLoad: Sendable, Equatable {
    var archive: SheetArchive
    var notice: String?
    var usedBackup: Bool
}

enum ArchiveFault: Equatable, Sendable {
    case writeFailed
}
