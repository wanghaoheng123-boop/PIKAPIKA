import SwiftUI
import SwiftData
import PikaCore

@main
struct PikaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Pet.self, BondEvent.self, ConversationMessage.self, SeasonalEvent.self])

        MenuBarExtra("Pika", systemImage: "pawprint.fill") {
            MenuBarContent()
        }
        .menuBarExtraStyle(.window)
    }
}
