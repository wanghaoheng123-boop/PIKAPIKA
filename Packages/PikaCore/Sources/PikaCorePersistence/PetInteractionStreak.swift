import Foundation

/// Daily visit streak. Call **before** updating `lastInteractedAt`.
public enum PetInteractionStreak {
    public static func recordInteraction(pet: Pet) {
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
}
