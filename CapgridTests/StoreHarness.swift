import Foundation
@testable import Capgrid

@MainActor
final class StoreHarness {
    let directory: URL
    let vault: SheetVault
    let store: SheetStore

    init(directory: URL, vault: SheetVault, store: SheetStore) {
        self.directory = directory
        self.vault = vault
        self.store = store
    }

    static func make() -> StoreHarness {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("capgrid-tests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let suite = "capgrid.tests.\(UUID().uuidString)"
        let vault = SheetVault(directory: directory, suiteName: suite)
        let store = SheetStore(vault: vault)
        return StoreHarness(directory: directory, vault: vault, store: store)
    }

    static func reopen(_ previous: StoreHarness) -> StoreHarness {
        let store = SheetStore(vault: previous.vault)
        return StoreHarness(directory: previous.directory, vault: previous.vault, store: store)
    }

    static func id(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", value)) ?? UUID()
    }
}
