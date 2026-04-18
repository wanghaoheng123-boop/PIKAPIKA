import XCTest
import PikaCoreBase

final class BondLevelTests: XCTestCase {

    func testFromXPThresholds() {
        XCTAssertEqual(BondLevel.from(xp: 0), .stranger)
        XCTAssertEqual(BondLevel.from(xp: 199), .stranger)
        XCTAssertEqual(BondLevel.from(xp: 200), .acquaintance)
        XCTAssertEqual(BondLevel.from(xp: 17_999), .soulBonded)
        XCTAssertEqual(BondLevel.from(xp: 18_000), .inseparable)
    }

    func testProgressAtBoundaries() {
        XCTAssertEqual(BondLevel.progress(xp: 0), 0)
        XCTAssertEqual(BondLevel.progress(xp: 200), 0)
        let mid = BondLevel.progress(xp: 400)
        XCTAssertGreaterThan(mid, 0)
        XCTAssertLessThan(mid, 1)
    }

    func testComparableOrdering() {
        XCTAssertLessThan(BondLevel.friend, BondLevel.bestFriend)
    }
}
