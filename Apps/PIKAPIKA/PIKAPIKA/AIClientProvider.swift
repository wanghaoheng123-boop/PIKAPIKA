import Foundation
import PikaAI
import PikaCoreBase

/// Uses [`RoutedAIClient`] when any vendor key exists (Anthropic, OpenAI, and/or DeepSeek); otherwise [`MockAIClient`].
enum AIClientProvider {
    static func currentClient() -> any AIClient {
        let open = (KeychainHelper.load(.openAIKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let ant = (KeychainHelper.load(.anthropicKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let ds = (KeychainHelper.load(.deepSeekKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !open.isEmpty || !ant.isEmpty || !ds.isEmpty else {
            return MockAIClient()
        }
        let raw = UserDefaults.standard.string(forKey: PikaUserDefaultsKeys.aiProviderPreference)
        let pref = AIProviderRouter.Preference(rawValue: raw ?? "") ?? .anthropicPrimary
        return RoutedAIClient(preference: pref)
    }
}
