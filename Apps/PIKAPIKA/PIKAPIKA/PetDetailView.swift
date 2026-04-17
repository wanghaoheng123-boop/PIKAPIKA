import SwiftUI
import PikaCore

struct PetDetailView: View {
    let pet: Pet

    var body: some View {
        List {
            Section("Bond") {
                LabeledContent("Tier", value: BondLevel.from(xp: pet.bondXP).displayName)
                LabeledContent("XP", value: "\(pet.bondXP)")
                LabeledContent("Level (cached)", value: "\(pet.bondLevel)")
            }
            Section {
                NavigationLink {
                    ChatView(pet: pet)
                } label: {
                    Label("Chat with pet", systemImage: "bubble.left.and.bubble.right.fill")
                }
            }
        }
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
