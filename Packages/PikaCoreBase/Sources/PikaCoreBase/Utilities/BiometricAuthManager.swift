import Foundation
import LocalAuthentication

/// Wraps LocalAuthentication for biometric (Face ID / Touch ID) prompts.
/// Used to protect API key reveal in Settings UI.
public final class BiometricAuthManager: Sendable {

    public static let shared = BiometricAuthManager()
    private init() {}

    /// Returns true if the device supports biometric authentication.
    public var isBiometricAvailable: Bool {
        let ctx = LAContext()
        var error: NSError?
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Prompt the user for biometric authentication.
    /// - Parameter reason: The string displayed in the system prompt.
    /// - Returns: `true` if authentication succeeded, `false` otherwise.
    public func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
        } catch {
            return false
        }
    }
}
