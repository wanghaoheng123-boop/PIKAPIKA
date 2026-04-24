import Foundation
import PikaCore

/// Daily visit streak (QQ-style stickiness). Call **before** updating `lastInteractedAt`.
enum PetInteractionStreak {
    static func recordInteraction(pet: Pet) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let lastDay = cal.startOfDay(for: pet.lastInteractedAt)
        guard today != lastDay else { return }
        let diff = cal.dateComponents([.day], from: lastDay, to: today).day ?? 0
        guard diff > 0 else { return }
        if diff == 1 {
            pet.streakCount += 1
        } else {
            pet.streakCount = 1
        }
        pet.longestStreak = max(pet.longestStreak, pet.streakCount)
    }
}
