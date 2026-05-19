import XCTest
@testable import Pika

final class PaywallCoordinatorTests: XCTestCase {
    private let sourceA = "test_paywall_a"
    private let sourceB = "test_paywall_b"

    override func tearDown() {
        PaywallPresentationGate.endAnyPresentation()
        clearCooldown(for: sourceA)
        clearCooldown(for: sourceB)
        super.tearDown()
    }

    func testGateBlocksConcurrentPresentation() {
        clearCooldown(for: sourceA)
        clearCooldown(for: sourceB)
        XCTAssertTrue(PaywallPresentationGate.beginPresentation(source: sourceA))
        XCTAssertFalse(PaywallPresentationGate.beginPresentation(source: sourceB))
        PaywallPresentationGate.endPresentation(source: sourceA)
        clearCooldown(for: sourceB)
        XCTAssertTrue(PaywallPresentationGate.beginPresentation(source: sourceB))
        PaywallPresentationGate.endPresentation(source: sourceB)
    }

    func testGateRespectsCooldownPerSource() {
        clearCooldown(for: sourceA)
        XCTAssertTrue(PaywallPresentationGate.beginPresentation(source: sourceA, cooldownSeconds: 120))
        PaywallPresentationGate.endPresentation(source: sourceA)
        XCTAssertFalse(PaywallPresentationGate.beginPresentation(source: sourceA, cooldownSeconds: 120))
    }

    func testEndAnyPresentationReleasesGate() {
        clearCooldown(for: sourceA)
        clearCooldown(for: sourceB)
        XCTAssertTrue(PaywallPresentationGate.beginPresentation(source: sourceA))
        PaywallPresentationGate.endAnyPresentation()
        clearCooldown(for: sourceB)
        XCTAssertTrue(PaywallPresentationGate.beginPresentation(source: sourceB))
        PaywallPresentationGate.endPresentation(source: sourceB)
    }

    private func clearCooldown(for source: String) {
        let key = "com.pikapika.analytics.subscription.paywall.cooldown.\(source)"
        UserDefaults.standard.removeObject(forKey: key)
    }
}
