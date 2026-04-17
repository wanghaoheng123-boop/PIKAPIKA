import SwiftUI
import SwiftData
import PikaCore

struct ContentView: View {
    @Query(sort: \Pet.name) private var pets: [Pet]

    var body: some View {
        NavigationStack {
            Group {
                if pets.isEmpty {
                    ContentUnavailableView(
                        "PIKAPIKA",
                        systemImage: "pawprint.fill",
                        description: Text("No pets yet — \(BondLevel.stranger.displayName) bond tier ready.")
                    )
                } else {
                    List {
                        ForEach(pets, id: \.id) { pet in
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
            .navigationTitle("PIKAPIKA")
        }
    }
}

