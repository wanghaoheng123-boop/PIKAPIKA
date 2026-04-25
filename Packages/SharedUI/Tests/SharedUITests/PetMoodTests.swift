import XCTest
import SharedUI
import PikaCoreBase

final class PetMoodTests: XCTestCase {
    func testAllMoodsHaveDisplayNameAndEmoji() {
        for mood in PetMood.allCases {
            XCTAssertFalse(mood.displayName.isEmpty)
            XCTAssertFalse(mood.emoji.isEmpty)
        }
    }

    func testMoodToStateMapping() {
        XCTAssertEqual(PetState.from(mood: .happy), .celebrating)
        XCTAssertEqual(PetState.from(mood: .excited), .celebrating)
        XCTAssertEqual(PetState.from(mood: .idle), .idle)
        XCTAssertEqual(PetState.from(mood: .sleepy), .sleeping)
        XCTAssertEqual(PetState.from(mood: .sad), .sad)
    }
}
