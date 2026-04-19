import SwiftUI
import SwiftData
import PikaCore

@main
struct PikaApp: App {
    /// One store for every scene. Without this, `MenuBarExtra`’s `@Query` runs in a scene that never received
    /// `.modelContainer`, which breaks SwiftData in the menu bar on macOS.
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for: Pet.self,
                BondEvent.self,
                ConversationMessage.self,
                SeasonalEvent.self,
                PetMemoryFact.self
            )
        } catch {
            fatalError("Could not open SwiftData store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)

        MenuBarExtra("Pika", systemImage: "pawprint.fill") {
            MenuBarContent()
        }
        .modelContainer(modelContainer)
        .menuBarExtraStyle(.window)
    }
}
