import XCTest
import PikaCorePersistence
import PikaCoreBase

final class BondProgressionTests: XCTestCase {

    func testWorkSessionXPIsCappedAt120() {
        let short = BondProgression.xp(for: .workSessionMinutes(20))
        let long = BondProgression.xp(for: .workSessionMinutes(600))
        XCTAssertEqual(short.xp, 10)
        XCTAssertEqual(long.xp, 120)
        XCTAssertEqual(long.eventType, "worksession")
    }

    func testApplyReturnsLevelUpWhenCrossingBoundary() {
        let before = BondLevel.acquaintance.xpThreshold - 1
        let award = BondProgression.xp(for: .chatMessage)
        let result = BondProgression.apply(currentXP: before, award: award)
        XCTAssertGreaterThan(result.newXP, before)
        XCTAssertNotNil(result.levelUp)
        XCTAssertEqual(result.levelUp?.from, .stranger)
        XCTAssertEqual(result.levelUp?.to, .acquaintance)
    }

    func testDailyCapConstantRemainsStable() {
        XCTAssertEqual(BondProgression.dailyCap, 400)
    }
}

