import SwiftUI

struct RootView: View {
    @Environment(AuthSession.self) private var authSession

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
