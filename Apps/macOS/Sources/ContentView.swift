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
                VStack(spacing: PikaTheme.Spacing.lg) {
                    Text("🐾").font(.system(size: 96))
                    Text("Create your first pet").font(PikaTheme.Typography.title)
                    Button("Get started") { showOnboarding = true }
                        .buttonStyle(.borderedProminent)
                }
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
