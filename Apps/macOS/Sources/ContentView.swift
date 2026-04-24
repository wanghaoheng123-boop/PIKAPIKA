import SwiftUI
import SwiftData
import PikaCore
import SharedUI

struct ContentView: View {
    @Query private var pets: [Pet]
    @Environment(\.modelContext) private var context
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if let pet = pets.first {
                PetHomeView(pet: pet)
            } else {
                EmptyStateView(
                    title: "Create your first pet",
                    message: "Your companion awaits. Let's bring them to life.",
                    icon: "pawprint.fill",
                    actionTitle: "Get started"
                ) { showOnboarding = true }
                    .frame(minWidth: 420, minHeight: 320)
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
