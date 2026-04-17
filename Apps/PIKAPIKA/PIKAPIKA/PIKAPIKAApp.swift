import SwiftUI
import SwiftData
import PikaCore

@main
struct PIKAPIKAApp: App {

    private let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            Pet.self,
            BondEvent.self,
            ConversationMessage.self,
            SeasonalEvent.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
