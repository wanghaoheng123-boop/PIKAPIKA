import Foundation
import Testing
import PikaCoreBase

@Suite("KeychainHelper")
struct KeychainHelperTests {

    @Test("save load roundtrip for OpenAI key")
    func openAIRoundtrip() {
        let key = KeychainHelper.Key.openAIKey
        let suffix = UUID().uuidString
        let value = "sk-test-\(suffix)"
        KeychainHelper.delete(key)
        #expect(KeychainHelper.save(value, for: key))
        #expect(KeychainHelper.load(key) == value)
        KeychainHelper.delete(key)
        #expect(KeychainHelper.load(key) == nil)
    }

    @Test("save load roundtrip for Apple user id")
    func appleUserRoundtrip() {
        let key = KeychainHelper.Key.appleUserId
        let value = "apple-\(UUID().uuidString)"
        KeychainHelper.delete(key)
        #expect(KeychainHelper.save(value, for: key))
        #expect(KeychainHelper.load(key) == value)
        KeychainHelper.delete(key)
    }
}
