import XCTest
import SharedUI
import PikaCoreBase

final class PikaSecuritySmokeTests: XCTestCase {
    func testMoodCountIsStable() {
        XCTAssertEqual(PetMood.allCases.count, 5)
    }

    func testNetworkUnavailableErrorDescriptionExists() {
        let message = AIClientError.networkUnavailable.errorDescription ?? ""
        XCTAssertFalse(message.isEmpty)
    }
}
