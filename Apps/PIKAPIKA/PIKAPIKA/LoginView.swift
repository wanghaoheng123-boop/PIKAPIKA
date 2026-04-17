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
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.35, green: 0.2, blue: 0.55),
                    PIKAPIKATheme.accent.opacity(0.95),
                    PIKAPIKATheme.warmth.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 112, height: 112)
                        Image(systemName: "pawprint.circle.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    }
                    Text("PIKAPIKA")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(1)
                    Text("An AI companion with spirit")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white.opacity(0.95))
                    Text("Care, chat, and daily moments — a living bond, not just a chat window.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.88))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                Spacer(minLength: 32)

                VStack(spacing: 14) {
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
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: PIKAPIKATheme.cornerMedium, style: .continuous))

                    Button {
                        Task { await signInGoogle() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "g.circle.fill")
                                .font(.title3)
                            Text("Sign in with Google")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(.white.opacity(0.95))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: PIKAPIKATheme.cornerMedium, style: .continuous))
                    }

                    Button {
                        authSession.signInGuest()
                    } label: {
                        Text("Try without signing in")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background {
                                RoundedRectangle(cornerRadius: PIKAPIKATheme.cornerMedium, style: .continuous)
                                    .strokeBorder(.white.opacity(0.85), lineWidth: 1.5)
                            }
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 28)

                Text(footerHint)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 20)

                Spacer(minLength: 40)
            }
        }
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
                "Add your iOS OAuth client ID as GIDClientID and the reversed client ID as a URL scheme in Info.plist (Google Cloud Console → APIs & Services → Credentials → OAuth 2.0 Client ID for iOS, bundle id com.pikapika.PIKAPIKA). Or use “Try without signing in” to try the app."
            )
        }
    }

    private var footerHint: String {
        var parts: [String] = []
        parts.append("Guest mode saves pets on this device.")
        if !isGoogleClientConfigured {
            parts.append("Google needs a real GIDClientID in Info.plist.")
        }
        parts.append("Enable Sign in with Apple for this App ID in the Developer portal.")
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
            if ns.code == -5, ns.domain.contains("GIDSignIn") {
                return
            }
            googleErrorMessage = error.localizedDescription
            showGoogleError = true
        }
    }

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
