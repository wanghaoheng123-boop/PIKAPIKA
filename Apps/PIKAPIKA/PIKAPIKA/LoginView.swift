import AuthenticationServices
import SwiftUI
import UIKit
import GoogleSignIn

struct LoginView: View {
    @Environment(AuthSession.self) private var authSession

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
                switch result {
                case .success(let authorization):
                    if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                        authSession.signInApple(userIdentifier: credential.user)
                    }
                case .failure:
                    break
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

            Text("Set GIDClientID and URL scheme in Info.plist for Google. Apple Sign In works in Simulator with an Apple ID.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    @MainActor
    private func signInGoogle() async {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
              !clientID.isEmpty,
              !clientID.hasPrefix("YOUR_") else {
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController ?? scene.windows.first?.rootViewController else {
            return
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: root)
            guard let uid = result.user.userID else { return }
            authSession.signInGoogle(userIdentifier: uid)
        } catch {
            // Cancelled or error
        }
    }
}
