import XCTest
import Foundation
import PikaCorePersistence

final class PetInteractionStreakTests: XCTestCase {

    private func makePet(lastInteractedAt: Date, streakCount: Int = 0, longest: Int = 0) -> Pet {
        Pet(
            name: "Test",
            species: "cat",
            creationMethod: "prompt",
            spriteAtlasPath: "",
            lastInteractedAt: lastInteractedAt,
            streakCount: streakCount,
            longestStreak: longest
        )
    }

    func testRecordStreakIncrementsForYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let pet = makePet(lastInteractedAt: yesterday, streakCount: 3, longest: 3)
        PetInteractionStreak.recordStreak(pet: pet)
        XCTAssertEqual(pet.streakCount, 4)
        XCTAssertEqual(pet.longestStreak, 4)
    }

    func testRecordStreakDoesNotChangeForSameDay() {
        let pet = makePet(lastInteractedAt: Date(), streakCount: 5, longest: 7)
        PetInteractionStreak.recordStreak(pet: pet)
        XCTAssertEqual(pet.streakCount, 5)
        XCTAssertEqual(pet.longestStreak, 7)
    }

    func testRecordStreakResetsAfterGapMoreThanOneDay() {
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let pet = makePet(lastInteractedAt: threeDaysAgo, streakCount: 9, longest: 11)
        PetInteractionStreak.recordStreak(pet: pet)
        XCTAssertEqual(pet.streakCount, 1)
        XCTAssertEqual(pet.longestStreak, 11)
    }

    func testRecordStreakIgnoresFutureDates() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let pet = makePet(lastInteractedAt: tomorrow, streakCount: 2, longest: 2)
        PetInteractionStreak.recordStreak(pet: pet)
        XCTAssertEqual(pet.streakCount, 2)
        XCTAssertEqual(pet.longestStreak, 2)
    }

    func testRecordXPEarnedRespectsDailyCap() {
        let petID = UUID()
        let first = PetInteractionStreak.recordXPEarned(petID: petID, amount: 300)
        let second = PetInteractionStreak.recordXPEarned(petID: petID, amount: 200)
        XCTAssertEqual(first, 300)
        XCTAssertEqual(second, 100)
        XCTAssertEqual(PetInteractionStreak.xpEarnedToday(petID: petID), 400)
        XCTAssertEqual(PetInteractionStreak.xpRemainingToday(petID: petID), 0)
    }
}

