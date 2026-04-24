import Foundation
import PikaCoreBase

/// XP curve, award rules, and level-up detection.
public struct BondProgression: Sendable {

    public enum Event: Sendable {
        case dailyCheckin
        case chatMessage
        case localCompanion
        case workSessionMinutes(Int)
        case feeding
        case milestone(String)
        case tapPet
        case tap
        case playSession
        case voiceMove
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

    /// XP awarded for an event. Diminishing returns per day are applied at the call site via `dailyCap`.
    public static func xp(for event: Event) -> Award {
        switch event {
        case .dailyCheckin:
            return Award(xp: 50, eventType: "checkin", metadata: nil)
        case .chatMessage:
            return Award(xp: 8, eventType: "chat", metadata: nil)
        case .localCompanion:
            return Award(xp: 2, eventType: "chat_local", metadata: nil)
        case .workSessionMinutes(let minutes):
            return Award(xp: min(Int(Double(minutes) / 2.0), 120), eventType: "worksession",
                         metadata: "\(minutes)m")
        case .feeding:
            return Award(xp: 15, eventType: "feed", metadata: nil)
        case .tapPet:
            return Award(xp: 4, eventType: "pet", metadata: nil)
        case .tap:
            return Award(xp: 3, eventType: "tap", metadata: nil)
        case .playSession:
            return Award(xp: 8, eventType: "play", metadata: nil)
        case .voiceMove:
            return Award(xp: 2, eventType: "voice_move", metadata: nil)
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
