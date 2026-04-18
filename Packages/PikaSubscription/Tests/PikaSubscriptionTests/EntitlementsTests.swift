import XCTest
@testable import PikaSubscription

final class EntitlementsTests: XCTestCase {

    func testProIncludesCloudSync() {
        XCTAssertTrue(Entitlements.pro.contains(.cloudSync))
        XCTAssertTrue(Entitlements.pro.contains(.unlimitedPets))
    }

    func testFreeIsEmpty() {
        XCTAssertTrue(Entitlements.free.isEmpty)
    }

    func testProductIDMapsToPro() {
        XCTAssertEqual(ProductID.proMonthly.entitlements, .pro)
        XCTAssertEqual(ProductID.proLifetime.entitlements, .pro)
    }
}
