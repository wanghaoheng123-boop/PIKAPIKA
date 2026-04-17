import SwiftUI

struct RootView: View {
    @EnvironmentObject private var authSession: AuthSession

    var body: some View {
        Group {
            if authSession.isSignedIn {
                PetListView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: authSession.isSignedIn)
        .tint(PIKAPIKATheme.accent)
    }
}
