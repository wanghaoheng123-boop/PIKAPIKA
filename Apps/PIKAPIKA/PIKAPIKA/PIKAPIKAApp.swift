import SwiftUI
import SwiftData
import GoogleSignIn
import PikaCore

@main
struct PIKAPIKAApp: App {

    @StateObject private var authSession = AuthSession()
    @State private var aiHolder = AIClientHolder()
    @Environment(\.scenePhase) private var scenePhase

    private let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            Pet.self,
            BondEvent.self,
            ConversationMessage.self,
            SeasonalEvent.self,
            PetMemoryFact.self
        ])
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [ModelConfiguration()])
        } catch {
            // Keep app bootable even if persistent store initialization fails.
            // This fallback uses an in-memory store so users can still open the app.
            do {
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
                )
                print("PIKAPIKAApp: persistent ModelContainer failed, using in-memory fallback: \(error)")
            } catch {
                fatalError("Failed to create both persistent and in-memory ModelContainer: \(error)")
            }
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
                .environmentObject(authSession)
                .environment(aiHolder)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        aiHolder.refresh()
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}
