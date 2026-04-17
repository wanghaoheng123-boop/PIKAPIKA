import Foundation
import PikaCoreBase

/// Chooses OpenAI when a key exists in Keychain; otherwise mock.
enum AIClientProvider {
    static func currentClient() -> any AIClient {
        if let key = KeychainHelper.load(.openAIKey), !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return OpenAIChatClient(apiKey: key)
        }
        return MockAIClient()
    }
}
