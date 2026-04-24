import Foundation
import Observation
import PikaCoreBase

/// Holds the active `AIClient` (mock vs routed cloud providers) and refreshes when Settings saves a key.
@Observable
final class AIClientHolder {
    var client: any AIClient
    var usagePolicy: AIUsagePolicy

    init() {
        self.client = AIClientProvider.currentClient()
        self.usagePolicy = AIUsagePolicyStore.load()
    }

    func refresh() {
        client = AIClientProvider.currentClient()
        usagePolicy = AIUsagePolicyStore.load()
    }

    var hasRemoteAI: Bool {
        let open = (KeychainHelper.load(.openAIKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let ant = (KeychainHelper.load(.anthropicKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let ds = (KeychainHelper.load(.deepSeekKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return !open.isEmpty || !ant.isEmpty || !ds.isEmpty
    }

    func saveUsagePolicy(_ policy: AIUsagePolicy) {
        usagePolicy = policy
        AIUsagePolicyStore.save(policy)
    }
}
