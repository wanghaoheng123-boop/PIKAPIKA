import SwiftUI
import SwiftData
import GoogleSignIn
import PikaCore

@main
struct PIKAPIKAApp: App {

    @State private var authSession = AuthSession()
    @State private var aiHolder = AIClientHolder()

    private let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            Pet.self,
            BondEvent.self,
            ConversationMessage.self,
            SeasonalEvent.self
        ])
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [ModelConfiguration()])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
           !clientID.isEmpty,
           !clientID.hasPrefix("YOUR_") {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authSession)
                .environment(aiHolder)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .modelContainer(modelContainer)
    }
}
