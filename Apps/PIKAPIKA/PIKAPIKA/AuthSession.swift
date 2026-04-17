import Combine
import Foundation
import PikaCoreBase

/// Tracks sign-in state for Sign in with Apple and Google Sign-In.
final class AuthSession: ObservableObject {

    enum Provider: String {
        case apple
        case google
    }

    @Published private(set) var isSignedIn = false
    @Published private(set) var provider: Provider?
    @Published private(set) var userId: String?

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

    @MainActor
    func signInApple(userIdentifier: String) {
        _ = KeychainHelper.save(userIdentifier, for: .appleUserId)
        KeychainHelper.delete(.googleUserId)
        provider = .apple
        userId = userIdentifier
        isSignedIn = true
    }

    @MainActor
    func signInGoogle(userIdentifier: String) {
        _ = KeychainHelper.save(userIdentifier, for: .googleUserId)
        KeychainHelper.delete(.appleUserId)
        provider = .google
        userId = userIdentifier
        isSignedIn = true
    }

    @MainActor
    func signOut() {
        KeychainHelper.delete(.appleUserId)
        KeychainHelper.delete(.googleUserId)
        provider = nil
        userId = nil
        isSignedIn = false
    }
}
