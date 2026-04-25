import Combine
import Foundation
import PikaCoreBase

/// Tracks sign-in state for Sign in with Apple and Google Sign-In.
final class AuthSession: ObservableObject {

    enum Provider: String {
        case apple
        case google
        /// Local-only session when Sign in with Apple / Google is not set up or fails.
        case guest
    }

    private static let guestUserDefaultsKey = "com.pikapika.PIKAPIKA.guestUserId"
    private static let guestIssuedAtKey = "com.pikapika.PIKAPIKA.guestIssuedAt"
    private static let maxGuestSessionAge: TimeInterval = 60 * 60 * 24 * 30

    @Published private(set) var isSignedIn = false
    @Published private(set) var provider: Provider?
    @Published private(set) var userId: String?

    init() {
        restoreFromKeychain()
    }

    @MainActor
    private func restoreFromKeychain() {
        if let id = KeychainHelper.load(.appleUserId), isValidUserIdentifier(id) {
            provider = .apple
            userId = id
            isSignedIn = true
            return
        }
        if let id = KeychainHelper.load(.googleUserId), isValidUserIdentifier(id) {
            provider = .google
            userId = id
            isSignedIn = true
            return
        }
        if let id = UserDefaults.standard.string(forKey: Self.guestUserDefaultsKey),
           isValidUserIdentifier(id),
           guestSessionIsFresh() {
            provider = .guest
            userId = id
            isSignedIn = true
        } else {
            UserDefaults.standard.removeObject(forKey: Self.guestUserDefaultsKey)
            UserDefaults.standard.removeObject(forKey: Self.guestIssuedAtKey)
        }
    }

    @MainActor
    func signInGuest() {
        KeychainHelper.delete(.appleUserId)
        KeychainHelper.delete(.googleUserId)
        let id = UserDefaults.standard.string(forKey: Self.guestUserDefaultsKey) ?? UUID().uuidString
        UserDefaults.standard.set(id, forKey: Self.guestUserDefaultsKey)
        UserDefaults.standard.set(Date(), forKey: Self.guestIssuedAtKey)
        provider = .guest
        userId = id
        isSignedIn = true
    }

    @MainActor
    func signInApple(userIdentifier: String) {
        guard isValidUserIdentifier(userIdentifier) else { return }
        UserDefaults.standard.removeObject(forKey: Self.guestUserDefaultsKey)
        UserDefaults.standard.removeObject(forKey: Self.guestIssuedAtKey)
        _ = KeychainHelper.save(userIdentifier, for: .appleUserId)
        KeychainHelper.delete(.googleUserId)
        provider = .apple
        userId = userIdentifier
        isSignedIn = true
    }

    @MainActor
    func signInGoogle(userIdentifier: String) {
        guard isValidUserIdentifier(userIdentifier) else { return }
        UserDefaults.standard.removeObject(forKey: Self.guestUserDefaultsKey)
        UserDefaults.standard.removeObject(forKey: Self.guestIssuedAtKey)
        _ = KeychainHelper.save(userIdentifier, for: .googleUserId)
        KeychainHelper.delete(.appleUserId)
        provider = .google
        userId = userIdentifier
        isSignedIn = true
    }

    @MainActor
    func signOut() {
        UserDefaults.standard.removeObject(forKey: Self.guestUserDefaultsKey)
        UserDefaults.standard.removeObject(forKey: Self.guestIssuedAtKey)
        KeychainHelper.delete(.appleUserId)
        KeychainHelper.delete(.googleUserId)
        provider = nil
        userId = nil
        isSignedIn = false
    }

    private func guestSessionIsFresh(now: Date = Date()) -> Bool {
        guard let issuedAt = UserDefaults.standard.object(forKey: Self.guestIssuedAtKey) as? Date else {
            return false
        }
        return now.timeIntervalSince(issuedAt) <= Self.maxGuestSessionAge
    }

    private func isValidUserIdentifier(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 8 && trimmed.count <= 256
    }
}
