import XCTest
import PikaCore
@testable import PetEngine

final class BondProgressionTests: XCTestCase {

    func testChatAwardXP() {
        let award = BondProgression.xp(for: .chatMessage)
        XCTAssertEqual(award.xp, 8)
        XCTAssertEqual(award.eventType, "chat")
    }

    func testWorkSessionCappedAt120() {
        let award = BondProgression.xp(for: .workSessionMinutes(600))
        XCTAssertEqual(award.xp, 120)
    }

    func testApplyDetectsLevelUp() {
        let award = BondProgression.Award(xp: 200, eventType: "test", metadata: nil)
        let result = BondProgression.apply(currentXP: 0, award: award)
        XCTAssertEqual(result.newXP, 200)
        XCTAssertEqual(result.levelUp?.to, .acquaintance)
    }

    func testApplyNoLevelUpWithinBand() {
        let award = BondProgression.Award(xp: 10, eventType: "test", metadata: nil)
        let result = BondProgression.apply(currentXP: 100, award: award)
        XCTAssertNil(result.levelUp)
        XCTAssertEqual(result.newXP, 110)
    }
}

final class PetBehaviorEngineTests: XCTestCase {

    func testSleepsAfterLongIdle() {
        let activity = UserActivity(idleSeconds: 500)
        let state = PetBehaviorEngine.proposedState(for: activity, sleepAfter: 300)
        XCTAssertEqual(state, .sleeping)
    }

    func testTypingIntensityClassification() {
        let activity = UserActivity(keystrokesPerMinute: 150)
        let state = PetBehaviorEngine.proposedState(for: activity, sleepAfter: 300)
        XCTAssertEqual(state, .typing(intensity: .frantic))
    }

    func testReactsToKnownApp() {
        let activity = UserActivity(keystrokesPerMinute: 0, activeApp: .coding)
        let state = PetBehaviorEngine.proposedState(for: activity, sleepAfter: 300)
        XCTAssertEqual(state, .reacting(context: .coding))
    }
}

final class AppContextMapperTests: XCTestCase {

    func testMapsXcodeToCoding() {
        XCTAssertEqual(AppContextMapper.context(for: "com.apple.dt.Xcode"), .coding)
    }

    func testMapsSpotifyToMusic() {
        XCTAssertEqual(AppContextMapper.context(for: "com.spotify.client"), .music)
    }

    func testUnknownBundleIsUnknown() {
        XCTAssertEqual(AppContextMapper.context(for: "com.example.nothing"), .unknown)
    }
}
