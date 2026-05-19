import Foundation

enum SubscriptionAnalytics {
    enum Event: String {
        case paywallShown = "paywall_shown"
        case purchaseStarted = "purchase_started"
        case purchaseSucceeded = "purchase_succeeded"
        case purchaseNotCompleted = "purchase_not_completed"
        case restoreTapped = "restore_tapped"
    }

    private static let prefix = "com.pikapika.analytics.subscription."
    private static let paywallCooldownPrefix = "com.pikapika.analytics.subscription.paywall.cooldown."
    private static let paywallCooldownLock = NSLock()

    @MainActor
    static func track(_ event: Event, source: String) {
        let defaults = UserDefaults.standard
        let key = "\(prefix)\(event.rawValue).\(source)"
        defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
        defaults.set(Date(), forKey: "\(key).lastAt")
    }

    static func shouldPresentPaywall(source: String, cooldownSeconds: TimeInterval = 90) -> Bool {
        paywallCooldownLock.lock()
        defer { paywallCooldownLock.unlock() }
        let defaults = UserDefaults.standard
        let key = "\(paywallCooldownPrefix)\(source)"
        if let lastShown = defaults.object(forKey: key) as? Date,
           Date().timeIntervalSince(lastShown) < cooldownSeconds {
            return false
        }
        defaults.set(Date(), forKey: key)
        return true
    }
}
