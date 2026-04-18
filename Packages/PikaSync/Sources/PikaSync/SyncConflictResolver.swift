import Foundation
import PikaCore

/// Resolves concurrent edits to a `Pet` record. The policy is last-writer-wins
/// on `lastInteractedAt`, with the monotonic `bondXP` always taking the max of
/// the two values (never regress progress).
public enum SyncConflictResolver {

    public struct RemotePetSnapshot: Sendable {
        public let bondXP: Int
        public let bondLevel: Int
        public let lastInteractedAt: Date
        public let streakCount: Int
        public let longestStreak: Int

        public init(
            bondXP: Int,
            bondLevel: Int,
            lastInteractedAt: Date,
            streakCount: Int,
            longestStreak: Int
        ) {
            self.bondXP = bondXP
            self.bondLevel = bondLevel
            self.lastInteractedAt = lastInteractedAt
            self.streakCount = streakCount
            self.longestStreak = longestStreak
        }
    }

    public static func merge(local: Pet, remote: RemotePetSnapshot) {
        let remoteNewer = remote.lastInteractedAt > local.lastInteractedAt

        // XP never regresses — take the max.
        local.bondXP = max(local.bondXP, remote.bondXP)
        local.bondLevel = BondLevel.from(xp: local.bondXP).rawValue

        // Streaks never regress.
        local.longestStreak = max(local.longestStreak, remote.longestStreak)

        if remoteNewer {
            local.streakCount = remote.streakCount
            local.lastInteractedAt = remote.lastInteractedAt
        }
    }
}
