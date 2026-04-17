import Testing
import PikaCoreBase

@Suite("BondLevel")
struct BondLevelTests {

    @Test("XP maps to correct bond tier")
    func fromXPThresholds() {
        #expect(BondLevel.from(xp: 0) == .stranger)
        #expect(BondLevel.from(xp: 199) == .stranger)
        #expect(BondLevel.from(xp: 200) == .acquaintance)
        #expect(BondLevel.from(xp: 17_999) == .soulBonded)
        #expect(BondLevel.from(xp: 18_000) == .inseparable)
    }

    @Test("Progress within level is between 0 and 1")
    func progressAtBoundaries() {
        #expect(BondLevel.progress(xp: 0) == 0)
        #expect(BondLevel.progress(xp: 200) == 0)
        let mid = BondLevel.progress(xp: 400)
        #expect(mid > 0)
        #expect(mid < 1)
    }

    @Test("Comparable ordering")
    func comparable() {
        #expect(BondLevel.friend < BondLevel.bestFriend)
    }
}
