import XCTest
import SharedUI
import PikaCoreBase

final class PikaSecuritySmokeTests: XCTestCase {
    func testMoodDisplayNamesAreUnique() {
        let names = Set(PetMood.allCases.map(\.displayName))
        XCTAssertEqual(names.count, PetMood.allCases.count)
    }

    func testMissingApiKeyErrorDescriptionExists() {
        let message = AIClientError.missingAPIKey.errorDescription ?? ""
        XCTAssertFalse(message.isEmpty)
    }
}
