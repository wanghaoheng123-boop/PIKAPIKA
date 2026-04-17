import XCTest
@testable import PIKAPIKA

@MainActor
final class AuthSessionTests: XCTestCase {

    func testSignInAppleAndSignOut() {
        let session = AuthSession()
        session.signOut()

        XCTAssertFalse(session.isSignedIn)
        XCTAssertNil(session.provider)

        let id = "unit-test-apple-\(UUID().uuidString)"
        session.signInApple(userIdentifier: id)

        XCTAssertTrue(session.isSignedIn)
        XCTAssertEqual(session.provider, .apple)
        XCTAssertEqual(session.userId, id)

        session.signOut()
        XCTAssertFalse(session.isSignedIn)
        XCTAssertNil(session.userId)
    }

    func testSignInGoogleReplacesApple() {
        let session = AuthSession()
        session.signOut()

        session.signInApple(userIdentifier: "apple-id")
        XCTAssertEqual(session.provider, .apple)

        session.signInGoogle(userIdentifier: "google-id")
        XCTAssertEqual(session.provider, .google)
        XCTAssertEqual(session.userId, "google-id")

        session.signOut()
    }

    func testNewSessionRestoresAppleFromKeychain() {
        let id = "unit-test-restore-\(UUID().uuidString)"
        let first = AuthSession()
        first.signOut()
        first.signInApple(userIdentifier: id)

        let second = AuthSession()
        XCTAssertTrue(second.isSignedIn, "Second session should restore from Keychain")
        XCTAssertEqual(second.userId, id)
        XCTAssertEqual(second.provider, .apple)

        second.signOut()
    }

    func testGuestSignInAndSignOut() {
        let session = AuthSession()
        session.signOut()

        session.signInGuest()
        XCTAssertTrue(session.isSignedIn)
        XCTAssertEqual(session.provider, .guest)
        XCTAssertNotNil(session.userId)

        session.signOut()
        XCTAssertFalse(session.isSignedIn)
    }
}
