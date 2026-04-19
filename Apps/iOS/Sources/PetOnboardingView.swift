import SwiftUI
import PikaCore
import SharedUI

struct PetOnboardingView: View {
    let onCreate: (Pet) -> Void

    @State private var name: String = ""
    @State private var species: String = "cat"
    @State private var traits: String = "playful, curious"
    @Environment(\.dismiss) private var dismiss

    private let speciesOptions = ["cat", "dog", "hamster", "fox", "rabbit"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") { TextField("e.g. Mochi", text: $name) }
                Section("Species") {
                    Picker("Species", selection: $species) {
                        ForEach(speciesOptions, id: \.self) { Text($0.capitalized).tag($0) }
                    }
                }
                Section("Personality (comma-separated)") {
                    TextField("playful, curious", text: $traits)
                }
            }
            .navigationTitle("New Pet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let pet = Pet(
                            name: name.isEmpty ? "Pika" : name,
                            species: species,
                            creationMethod: "prompt",
                            spriteAtlasPath: "",
                            personalityTraits: traits
                                .split(separator: ",")
                                .map { $0.trimmingCharacters(in: .whitespaces) }
                                .filter { !$0.isEmpty },
                            visualModelPreset: Pet.defaultVisualModelPreset(forSpecies: species)
                        )
                        onCreate(pet)
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
