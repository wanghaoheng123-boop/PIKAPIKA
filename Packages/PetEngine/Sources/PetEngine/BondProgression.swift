import Foundation
import PikaCore

/// XP curve, award rules, and level-up detection.
public struct BondProgression: Sendable {

    public enum Event: Sendable {
        case dailyCheckin
        case chatMessage
        case workSessionMinutes(Int)
        case feeding
        case milestone(String)
    }

    public struct Award: Sendable, Equatable {
        public let xp: Int
        public let eventType: String
        public let metadata: String?
    }

    public struct LevelUp: Sendable, Equatable {
        public let from: BondLevel
        public let to: BondLevel
        public let newlyUnlockedAnimations: [String]
    }

    /// XP awarded for an event. Diminishing returns per day are applied
    /// at the call site via `dailyCap`.
    public static func xp(for event: Event) -> Award {
        switch event {
        case .dailyCheckin:
            return Award(xp: 50, eventType: "checkin", metadata: nil)
        case .chatMessage:
            return Award(xp: 8, eventType: "chat", metadata: nil)
        case .workSessionMinutes(let minutes):
            // 1 XP per 2 minutes, capped at 120 per session.
            return Award(xp: min(minutes / 2, 120), eventType: "worksession",
                         metadata: "\(minutes)m")
        case .feeding:
            return Award(xp: 15, eventType: "feed", metadata: nil)
        case .milestone(let key):
            return Award(xp: 250, eventType: "milestone", metadata: key)
        }
    }

    /// Apply XP to the current total and return any level-up info.
    public static func apply(
        currentXP: Int,
        award: Award
    ) -> (newXP: Int, levelUp: LevelUp?) {
        let before = BondLevel.from(xp: currentXP)
        let after = BondLevel.from(xp: currentXP + award.xp)
        let levelUp: LevelUp? = after > before
            ? LevelUp(from: before, to: after, newlyUnlockedAnimations: after.unlockedAnimations)
            : nil
        return (currentXP + award.xp, levelUp)
    }

    /// Cap total XP earned today to prevent farming.
    public static let dailyCap: Int = 400
}
