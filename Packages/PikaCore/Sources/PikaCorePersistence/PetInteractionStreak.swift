import Foundation
import SwiftData
import PikaCoreBase

/// Daily visit streak tracking and XP-cap enforcement via UserDefaults.
public enum PetInteractionStreak {

    private static let dailyXPKey      = "Pika_dailyXP_%@"
    private static let dailyDateKey    = "Pika_dailyXPDate_%@"
<<<<<<< HEAD
=======
    private static let dailyXPLock = NSLock()
>>>>>>> ec0be87 (chore: checkpoint autonomous quality and orchestration updates)

    // MARK: - Streak

    /// Updates streak counters. Call **before** updating `lastInteractedAt`.
    public static func recordStreak(pet: Pet) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let lastDay = cal.startOfDay(for: pet.lastInteractedAt)
        guard today != lastDay else { return }
        let diff = cal.dateComponents([.day], from: lastDay, to: today).day ?? 0
        if diff == 1 {
            pet.streakCount += 1
        } else {
            pet.streakCount = 1
        }
        pet.longestStreak = max(pet.longestStreak, pet.streakCount)
    }

    // MARK: - Daily XP Cap

    /// XP earned so far today (resets at local midnight).
    public static func xpEarnedToday(petID: UUID) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dateKey = String(format: Self.dailyDateKey, petID.uuidString)
        let storedDate = UserDefaults.standard.object(forKey: dateKey) as? Date ?? .distantPast
        guard cal.startOfDay(for: storedDate) == today else { return 0 }
        let key = String(format: Self.dailyXPKey, petID.uuidString)
        return UserDefaults.standard.integer(forKey: key)
    }

    /// How much XP can still be earned today before hitting `BondProgression.dailyCap`.
    public static func xpRemainingToday(petID: UUID) -> Int {
        max(0, BondProgression.dailyCap - xpEarnedToday(petID: petID))
    }

    /// Records XP earned toward today's cap and returns the amount actually awarded
    /// (capped at the remaining daily budget).
    @discardableResult
    public static func recordXPEarned(petID: UUID, amount: Int) -> Int {
<<<<<<< HEAD
=======
        dailyXPLock.lock()
        defer { dailyXPLock.unlock() }

>>>>>>> ec0be87 (chore: checkpoint autonomous quality and orchestration updates)
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dateKey = String(format: Self.dailyDateKey, petID.uuidString)
        let storedDate = UserDefaults.standard.object(forKey: dateKey) as? Date ?? .distantPast
        let storedDay = cal.startOfDay(for: storedDate)

        var earnedToday: Int
        if storedDay == today {
            earnedToday = UserDefaults.standard.integer(forKey: String(format: Self.dailyXPKey, petID.uuidString))
        } else {
            earnedToday = 0
        }

        let remaining = BondProgression.dailyCap - earnedToday
        let awarded = min(amount, remaining)
        guard awarded > 0 else { return 0 }

        UserDefaults.standard.set(earnedToday + awarded, forKey: String(format: Self.dailyXPKey, petID.uuidString))
        UserDefaults.standard.set(today, forKey: dateKey)
        return awarded
    }
<<<<<<< HEAD
=======

    /// Backward-compatible alias used by older app surfaces.
    public static func recordInteraction(pet: Pet) {
        recordStreak(pet: pet)
    }

    public struct BondAwardOutcome: Sendable {
        public let awardedXP: Int
        public let levelUp: BondProgression.LevelUp?
    }

    /// Applies a bond event with shared cap enforcement and analytics write-through.
    @discardableResult
    public static func applyBondEvent(
        _ event: BondProgression.Event,
        to pet: Pet,
        modelContext: ModelContext,
        now: Date = Date()
    ) throws -> BondAwardOutcome {
        let award = BondProgression.xp(for: event)
        let awardedXP = recordXPEarned(petID: pet.id, amount: award.xp)
        guard awardedXP > 0 else {
            return BondAwardOutcome(awardedXP: 0, levelUp: nil)
        }

        let cappedAward = BondProgression.Award(
            xp: awardedXP,
            eventType: award.eventType,
            metadata: award.metadata
        )
        let applied = BondProgression.apply(currentXP: pet.bondXP, award: cappedAward)
        pet.bondXP = applied.newXP
        pet.bondLevel = BondLevel.from(xp: pet.bondXP).rawValue
        recordStreak(pet: pet)
        pet.lastInteractedAt = now

        modelContext.insert(
            BondEvent(
                pet: pet,
                eventType: cappedAward.eventType,
                xpAwarded: cappedAward.xp,
                timestamp: now,
                metadata: cappedAward.metadata
            )
        )
        try modelContext.save()
        return BondAwardOutcome(awardedXP: awardedXP, levelUp: applied.levelUp)
    }
>>>>>>> ec0be87 (chore: checkpoint autonomous quality and orchestration updates)
}
