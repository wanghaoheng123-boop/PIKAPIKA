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
        VStack(spacing: 24) {
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

            Text(googleSetupHint)
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
                "Replace GIDClientID and the reversed client ID URL scheme in Info.plist with values from Google Cloud Console (OAuth client ID for iOS, bundle id com.pikapika.PIKAPIKA)."
            )
        }
    }

    private var googleSetupHint: String {
        if isGoogleClientConfigured {
            return "Apple: sign in with your Apple ID in Simulator Settings if prompted. Google: uses your OAuth client in Info.plist."
        }
        return "Google is disabled until you set a real GIDClientID in Info.plist (see alert when you tap the button)."
    }

    private var isGoogleClientConfigured: Bool {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else { return false }
        return !clientID.isEmpty && !clientID.hasPrefix("YOUR_")
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
            googleErrorMessage = "Could not find a window to present Google sign-in."
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
            googleErrorMessage = error.localizedDescription
            showGoogleError = true
        }
    }

    /// Picks a view controller suitable for `GIDSignIn` presentation (key window / topmost).
    private static func presentingViewControllerForSignIn() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
        guard let windowScene = scene else { return nil }
        let window = windowScene.windows.first(where: \.isKeyWindow) ?? windowScene.windows.first
        guard let root = window?.rootViewController else { return nil }
        return root.topMostViewController
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
