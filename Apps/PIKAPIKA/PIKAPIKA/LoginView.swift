import AuthenticationServices
import SwiftUI
import UIKit
import GoogleSignIn

struct LoginView: View {
    @EnvironmentObject private var authSession: AuthSession

    @State private var appleErrorMessage: String?
    @State private var showAppleError = false
    @State private var googleErrorMessage: String?
    @State private var showGoogleError = false
    @State private var showGoogleNotConfigured = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.tint)
            Text("PIKAPIKA")
                .font(.largeTitle.bold())
            Text("Sign in to continue")
                .foregroundStyle(.secondary)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                Task { @MainActor in
                    switch result {
                    case .success(let authorization):
                        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                            authSession.signInApple(userIdentifier: credential.user)
                        } else {
                            appleErrorMessage = "Unexpected credential type. Try again."
                            showAppleError = true
                        }
                    case .failure(let error):
                        if isAppleUserCanceled(error) {
                            return
                        }
                        appleErrorMessage = error.localizedDescription
                        showAppleError = true
                    }
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal, 24)

            Button {
                Task { await signInGoogle() }
            } label: {
                HStack {
                    Image(systemName: "g.circle.fill")
                    Text("Sign in with Google")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 24)

            Button {
                authSession.signInGuest()
            } label: {
                Text("Continue without account")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal, 24)

            Text(footerHint)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .alert("Sign in with Apple failed", isPresented: $showAppleError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appleErrorMessage ?? "Unknown error.")
        }
        .alert("Google Sign-In failed", isPresented: $showGoogleError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(googleErrorMessage ?? "Unknown error.")
        }
        .alert("Google Sign-In not configured", isPresented: $showGoogleNotConfigured) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                "Add your iOS OAuth client ID as GIDClientID and the reversed client ID as a URL scheme in Info.plist (Google Cloud Console → APIs & Services → Credentials → OAuth 2.0 Client ID for iOS, bundle id com.pikapika.PIKAPIKA). Or use “Continue without account” to try the app."
            )
        }
    }

    private var footerHint: String {
        var parts: [String] = []
        parts.append("Use “Continue without account” to try pets and chat without Apple or Google.")
        if !isGoogleClientConfigured {
            parts.append("Google needs a real GIDClientID in Info.plist.")
        }
        parts.append("Apple needs Sign in with Apple enabled for this App ID in the Apple Developer portal.")
        return parts.joined(separator: " ")
    }

    private var isGoogleClientConfigured: Bool {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else { return false }
        return !clientID.isEmpty && !clientID.hasPrefix("YOUR_")
    }

    private func isAppleUserCanceled(_ error: Error) -> Bool {
        let ns = error as NSError
        if ns.domain == ASAuthorizationError.errorDomain, ns.code == ASAuthorizationError.canceled.rawValue {
            return true
        }
        if let auth = error as? ASAuthorizationError, auth.code == .canceled {
            return true
        }
        return false
    }

    @MainActor
    private func signInGoogle() async {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
              !clientID.isEmpty,
              !clientID.hasPrefix("YOUR_") else {
            showGoogleNotConfigured = true
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard let presenting = Self.presentingViewControllerForSignIn() else {
            googleErrorMessage = "Could not find a window to present Google sign-in. Try again after the app finishes launching."
            showGoogleError = true
            return
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)
            guard let uid = result.user.userID else {
                googleErrorMessage = "Google did not return a user id."
                showGoogleError = true
                return
            }
            authSession.signInGoogle(userIdentifier: uid)
        } catch {
            let ns = error as NSError
            // kGIDSignInErrorCodeCanceled == -5
            if ns.code == -5, ns.domain.contains("GIDSignIn") {
                return
            }
            googleErrorMessage = error.localizedDescription
            showGoogleError = true
        }
    }

    /// Resolves a view controller for Google Sign-In across all connected window scenes (key window is not always set during launch).
    private static func presentingViewControllerForSignIn() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            let ordered = scene.windows.sorted { a, b in
                if a.isKeyWindow != b.isKeyWindow { return a.isKeyWindow && !b.isKeyWindow }
                return a.windowLevel > b.windowLevel
            }
            for window in ordered where !window.isHidden && window.alpha > 0 {
                if let root = window.rootViewController {
                    return root.topMostViewController
                }
            }
        }
        return nil
    }
}

private extension UIViewController {
    var topMostViewController: UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController
        }
        if let nav = self as? UINavigationController, let visible = nav.visibleViewController {
            return visible.topMostViewController
        }
        if let tab = self as? UITabBarController, let selected = tab.selectedViewController {
            return selected.topMostViewController
        }
        return self
    }
}
