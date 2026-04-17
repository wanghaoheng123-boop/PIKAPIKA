import Foundation
import Observation
import PikaCoreBase

/// Tracks sign-in state for Sign in with Apple and Google Sign-In.
@Observable
final class AuthSession {

    enum Provider: String {
        case apple
        case google
    }

    private(set) var isSignedIn = false
    private(set) var provider: Provider?
    private(set) var userId: String?

    init() {
        restoreFromKeychain()
    }

    private func restoreFromKeychain() {
        if let id = KeychainHelper.load(.appleUserId), !id.isEmpty {
            provider = .apple
            userId = id
            isSignedIn = true
            return
        }
        if let id = KeychainHelper.load(.googleUserId), !id.isEmpty {
            provider = .google
            userId = id
            isSignedIn = true
        }
    }

    func signInApple(userIdentifier: String) {
        KeychainHelper.save(userIdentifier, for: .appleUserId)
        KeychainHelper.delete(.googleUserId)
        provider = .apple
        userId = userIdentifier
        isSignedIn = true
    }

    func signInGoogle(userIdentifier: String) {
        KeychainHelper.save(userIdentifier, for: .googleUserId)
        KeychainHelper.delete(.appleUserId)
        provider = .google
        userId = userIdentifier
        isSignedIn = true
    }

    func signOut() {
        KeychainHelper.delete(.appleUserId)
        KeychainHelper.delete(.googleUserId)
        provider = nil
        userId = nil
        isSignedIn = false
    }
}
