import SwiftUI
import SwiftData
import PikaCore
import SharedUI

struct ContentView: View {
    @Query private var pets: [Pet]
    @Environment(\.modelContext) private var context
    @State private var showOnboarding = false

    var body: some View {
        NavigationStack {
            Group {
                if let pet = pets.first {
                    PetHomeView(pet: pet)
                } else {
                    EmptyStateView(
                        title: "No pet yet",
                        message: "Let's create one together.",
                        icon: "pawprint.fill",
                        actionTitle: "Create my pet"
                    ) { showOnboarding = true }
                }
            }
            .navigationTitle("Pika")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showOnboarding) {
                PetOnboardingView { newPet in
                    context.insert(newPet)
                    showOnboarding = false
                }
            }
        }
    }
}
