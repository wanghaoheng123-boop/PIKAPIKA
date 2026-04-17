import Foundation

/// The 10-level bond relationship progression between user and pet.
/// Each level unlocks new animations, dialogue options, and cosmetics.
public enum BondLevel: Int, CaseIterable, Comparable, Sendable {
    case stranger       = 0
    case acquaintance   = 1
    case friendly       = 2
    case friend         = 3
    case goodFriend     = 4
    case closeFriend    = 5
    case bestFriend     = 6
    case bonded         = 7
    case soulBonded     = 8
    case inseparable    = 9

    public static func < (lhs: BondLevel, rhs: BondLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var displayName: String {
        switch self {
        case .stranger:     return "Stranger"
        case .acquaintance: return "Acquaintance"
        case .friendly:     return "Friendly"
        case .friend:       return "Friend"
        case .goodFriend:   return "Good Friend"
        case .closeFriend:  return "Close Friend"
        case .bestFriend:   return "Best Friend"
        case .bonded:       return "Bonded"
        case .soulBonded:   return "Soul Bonded"
        case .inseparable:  return "Inseparable"
        }
    }

    /// Total XP required to reach this level (cumulative from level 0).
    public var xpThreshold: Int {
        switch self {
        case .stranger:     return 0
        case .acquaintance: return 200
        case .friendly:     return 600
        case .friend:       return 1_200
        case .goodFriend:   return 2_200
        case .closeFriend:  return 3_800
        case .bestFriend:   return 6_000
        case .bonded:       return 9_000
        case .soulBonded:   return 13_000
        case .inseparable:  return 18_000
        }
    }

    /// XP needed for the next level (0 if already at max).
    public var xpToNextLevel: Int {
        guard let next = BondLevel(rawValue: rawValue + 1) else { return 0 }
        return next.xpThreshold - xpThreshold
    }

    /// Animation keys unlocked at this level.
    public var unlockedAnimations: [String] {
        switch self {
        case .stranger:     return ["idle_loop", "sleep_loop", "type_slow", "type_medium"]
        case .acquaintance: return ["type_fast", "react_browse", "react_write"]
        case .friendly:     return ["type_frantic", "react_code", "react_chat", "eat_loop"]
        case .friend:       return ["react_dance", "react_terminal", "curious_loop", "sad_loop"]
        case .goodFriend:   return ["react_art", "react_watch", "chat_bubble"]
        case .closeFriend:  return ["react_email", "celebrate_once", "sleep_snore"]
        case .bestFriend:   return ["rare_stretch", "rare_wink", "rare_yawn"]
        case .bonded:       return ["rare_headbang", "rare_backflip"]
        case .soulBonded:   return ["rare_glow", "rare_sparkle"]
        case .inseparable:  return ["rare_legendary_idle"]
        }
    }

    /// Notification copy style for "pet misses you" messages.
    public var missingYouCopy: [String] {
        switch self {
        case .stranger, .acquaintance:
            return [
                "{name} is waiting for you.",
                "Your pet hasn't seen you in a while."
            ]
        case .friendly, .friend, .goodFriend:
            return [
                "{name} is wondering where you went.",
                "{name} keeps looking at the door.",
                "Is everything okay? {name} misses you."
            ]
        case .closeFriend, .bestFriend:
            return [
                "{name} is pacing around looking for you...",
                "{name} hasn't eaten much. They miss you.",
                "Come back soon — {name} saved you a spot."
            ]
        case .bonded, .soulBonded, .inseparable:
            return [
                "{name} made something for you. Come see?",
                "It's not the same without you. {name} waits.",
                "{name} fell asleep holding your photo. Please come back."
            ]
        }
    }

    /// Derive bond level from raw XP value.
    public static func from(xp: Int) -> BondLevel {
        BondLevel.allCases.last(where: { xp >= $0.xpThreshold }) ?? .stranger
    }

    /// Progress (0.0–1.0) within the current level toward the next.
    public static func progress(xp: Int) -> Double {
        let current = from(xp: xp)
        guard let next = BondLevel(rawValue: current.rawValue + 1) else { return 1.0 }
        let xpIntoLevel = Double(xp - current.xpThreshold)
        let xpNeeded = Double(next.xpThreshold - current.xpThreshold)
        return min(xpIntoLevel / xpNeeded, 1.0)
    }
}
