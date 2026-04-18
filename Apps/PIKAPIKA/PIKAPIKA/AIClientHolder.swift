import Foundation
import Observation
import PikaCoreBase

/// Holds the active `AIClient` (mock vs OpenAI) and refreshes when Settings saves a key.
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
        !(client is MockAIClient)
    }

    func saveUsagePolicy(_ policy: AIUsagePolicy) {
        usagePolicy = policy
        AIUsagePolicyStore.save(policy)
    }
}
