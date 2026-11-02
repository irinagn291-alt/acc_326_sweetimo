import XCTest
@testable import Capgrid

final class ReviewLaunchTests: XCTestCase {
    func testReviewScreenParserReadsTheKeyAfterTheFlag() {
        XCTAssertEqual(
            ReviewLaunch.screen(in: ["Capgrid", "-ReviewScreen", "today"]),
            "today"
        )
        XCTAssertEqual(
            ReviewLaunch.screen(in: ["Capgrid", "-ReviewScreen", "log"]),
            "log"
        )
        XCTAssertEqual(
            ReviewLaunch.screen(in: ["Capgrid", "-ReviewScreen", "goals"]),
            "goals"
        )
        XCTAssertEqual(
            ReviewLaunch.screen(in: ["Capgrid", "-ReviewScreen", "matches"]),
            "matches"
        )
        XCTAssertNil(ReviewLaunch.screen(in: ["Capgrid"]))
        XCTAssertNil(ReviewLaunch.screen(in: ["Capgrid", "-ReviewScreen"]))
    }
}
