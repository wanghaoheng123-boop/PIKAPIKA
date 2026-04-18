import Foundation

/// Feature gates unlocked by an active subscription.
public struct Entitlements: OptionSet, Sendable, Hashable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let proPersonalities = Entitlements(rawValue: 1 << 0)
    public static let cloudSync        = Entitlements(rawValue: 1 << 1)
    public static let unlimitedPets    = Entitlements(rawValue: 1 << 2)
    public static let premiumSprites   = Entitlements(rawValue: 1 << 3)
    public static let seasonalEvents   = Entitlements(rawValue: 1 << 4)

    public static let free: Entitlements = []
    public static let pro: Entitlements  = [.proPersonalities, .cloudSync, .unlimitedPets,
                                            .premiumSprites, .seasonalEvents]
}

/// Product identifiers configured in App Store Connect.
public enum ProductID: String, CaseIterable, Sendable {
    case proMonthly = "com.pikapika.pro.monthly"
    case proYearly  = "com.pikapika.pro.yearly"
    case proLifetime = "com.pikapika.pro.lifetime"

    public var entitlements: Entitlements { .pro }
}
