import SwiftUI
import SwiftData
import PikaCore

struct PetListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Pet.name) private var pets: [Pet]
    @State private var showAddPet = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if pets.isEmpty {
                    ContentUnavailableView(
                        "PIKAPIKA",
                        systemImage: "pawprint.fill",
                        description: Text("Tap + to create your first pet.")
                    )
                } else {
                    List {
                        ForEach(pets, id: \.id) { pet in
                            NavigationLink {
                                PetDetailView(pet: pet)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(pet.name)
                                        .font(.headline)
                                    Text("Level \(pet.bondLevel) · \(BondLevel.from(xp: pet.bondXP).displayName)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Pets")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddPet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Add pet")
                }
            }
            .sheet(isPresented: $showAddPet) {
                AddPetSheet()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}
