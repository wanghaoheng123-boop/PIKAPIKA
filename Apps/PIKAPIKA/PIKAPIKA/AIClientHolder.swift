import Foundation
import Observation
import PikaCoreBase

/// Holds the active `AIClient` (mock vs OpenAI) and refreshes when Settings saves a key.
@Observable
final class AIClientHolder {
    var client: any AIClient

    init() {
        self.client = AIClientProvider.currentClient()
    }

    func refresh() {
        client = AIClientProvider.currentClient()
    }
}
