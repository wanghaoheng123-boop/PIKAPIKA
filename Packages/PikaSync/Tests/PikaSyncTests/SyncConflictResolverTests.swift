import XCTest
import PikaCore
@testable import PikaSync

final class SyncConflictResolverTests: XCTestCase {

    func testXPTakesMaxBothDirections() {
        let pet = Pet(name: "A", species: "cat", creationMethod: "prompt",
                      spriteAtlasPath: "", bondXP: 100)
        let remote = SyncConflictResolver.RemotePetSnapshot(
            bondXP: 250, bondLevel: 1,
            lastInteractedAt: Date().addingTimeInterval(-60),
            streakCount: 2, longestStreak: 3
        )
        SyncConflictResolver.merge(local: pet, remote: remote)
        XCTAssertEqual(pet.bondXP, 250)
        XCTAssertEqual(pet.bondLevel, BondLevel.acquaintance.rawValue)
        XCTAssertEqual(pet.longestStreak, 3)
    }

    func testNewerRemoteWinsStreak() {
        let pet = Pet(name: "A", species: "cat", creationMethod: "prompt",
                      spriteAtlasPath: "", streakCount: 1,
                      longestStreak: 5)
        pet.lastInteractedAt = Date().addingTimeInterval(-120)
        let remote = SyncConflictResolver.RemotePetSnapshot(
            bondXP: 0, bondLevel: 0,
            lastInteractedAt: Date(),
            streakCount: 7, longestStreak: 7
        )
        SyncConflictResolver.merge(local: pet, remote: remote)
        XCTAssertEqual(pet.streakCount, 7)
        XCTAssertEqual(pet.longestStreak, 7)
    }
}
