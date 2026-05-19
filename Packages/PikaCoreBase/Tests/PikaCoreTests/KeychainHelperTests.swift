import XCTest
import PikaCoreBase

final class KeychainHelperTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        if ProcessInfo.processInfo.environment["GITHUB_ACTIONS"] == "true" {
            throw XCTSkip("Keychain round-trip tests are unreliable on GitHub Actions runners; run locally on a Mac.")
        }
    }

    func testOpenAIRoundtrip() {
        let key = KeychainHelper.Key.openAIKey
        let suffix = UUID().uuidString
        let value = "sk-test-\(suffix)"
        KeychainHelper.delete(key)
        XCTAssertTrue(KeychainHelper.save(value, for: key))
        XCTAssertEqual(KeychainHelper.load(key), value)
        KeychainHelper.delete(key)
        XCTAssertNil(KeychainHelper.load(key))
    }

    func testDeepSeekKeyRoundtrip() {
        let key = KeychainHelper.Key.deepSeekKey
        let suffix = UUID().uuidString
        let value = "ds-test-\(suffix)"
        KeychainHelper.delete(key)
        XCTAssertTrue(KeychainHelper.save(value, for: key))
        XCTAssertEqual(KeychainHelper.load(key), value)
        KeychainHelper.delete(key)
        XCTAssertNil(KeychainHelper.load(key))
    }

    func testAppleUserRoundtrip() {
        let key = KeychainHelper.Key.appleUserId
        let value = "apple-\(UUID().uuidString)"
        KeychainHelper.delete(key)
        XCTAssertTrue(KeychainHelper.save(value, for: key))
        XCTAssertEqual(KeychainHelper.load(key), value)
        KeychainHelper.delete(key)
    }
}
