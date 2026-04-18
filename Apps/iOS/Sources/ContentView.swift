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
                    EmptyStateView { showOnboarding = true }
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

private struct EmptyStateView: View {
    let onCreate: () -> Void
    var body: some View {
        VStack(spacing: PikaTheme.Spacing.lg) {
            Text("🐾").font(.system(size: 80))
            Text("No pet yet").font(PikaTheme.Typography.title)
            Text("Let's create one together.").foregroundStyle(PikaTheme.Palette.textMuted)
            HapticButton(action: onCreate) { Text("Create my pet") }
                .padding(.horizontal, PikaTheme.Spacing.xl)
        }
        .padding()
    }
}
