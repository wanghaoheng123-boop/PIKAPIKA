import Foundation

enum PaywallPresentationGate {
    private static let lock = NSLock()
    private static var activeSource: String?

    static func beginPresentation(source: String, cooldownSeconds: TimeInterval = 90) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard activeSource == nil else { return false }
        guard SubscriptionAnalytics.shouldPresentPaywall(source: source, cooldownSeconds: cooldownSeconds) else {
            return false
        }
        activeSource = source
        return true
    }

    static func endPresentation(source: String) {
        lock.lock()
        defer { lock.unlock() }
        if activeSource == source {
            activeSource = nil
        }
    }

    static func endAnyPresentation() {
        lock.lock()
        defer { lock.unlock() }
        activeSource = nil
    }
}
