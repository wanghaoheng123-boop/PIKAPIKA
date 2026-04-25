import PikaSubscription

enum SharedSubscriptionManager {
    static let instance = SubscriptionManager()
    @MainActor private static var lastSuccessfulRefreshAt: Date = .distantPast
    @MainActor private static var inFlightRefresh: Task<Void, Never>?

    @MainActor
    static func refreshIfNeeded(minInterval: TimeInterval = 15) async {
        if let inFlightRefresh {
            await inFlightRefresh.value
            return
        }
        let now = Date()
        guard now.timeIntervalSince(lastSuccessfulRefreshAt) >= minInterval else { return }
        let task = Task { @MainActor in
            await instance.loadProducts()
            await instance.refreshEntitlements()
            if instance.lastErrorMessage == nil {
                lastSuccessfulRefreshAt = Date()
            }
        }
        inFlightRefresh = task
        await task.value
        inFlightRefresh = nil
    }

    @MainActor
    static func forceRefresh() async {
        if let inFlightRefresh {
            await inFlightRefresh.value
            return
        }
        let task = Task { @MainActor in
            await instance.loadProducts()
            await instance.refreshEntitlements()
            if instance.lastErrorMessage == nil {
                lastSuccessfulRefreshAt = Date()
            }
        }
        inFlightRefresh = task
        await task.value
        inFlightRefresh = nil
    }

    @MainActor
    static func latestErrorMessage() -> String? {
        instance.lastErrorMessage
    }
}
