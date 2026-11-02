import XCTest
@testable import Capgrid

final class CapgridTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: CapgridApp.self), "CapgridApp")
    }
}
