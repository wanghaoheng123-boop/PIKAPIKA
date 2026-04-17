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
    }
}
