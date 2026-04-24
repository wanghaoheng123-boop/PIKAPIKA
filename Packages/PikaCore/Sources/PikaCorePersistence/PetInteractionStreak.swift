import Foundation

/// Daily visit streak tracking and XP-cap enforcement via UserDefaults.
public enum PetInteractionStreak {

    private static let dailyXPKey      = "Pika_dailyXP_%@"
    private static let dailyDateKey    = "Pika_dailyXPDate_%@"

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
}
