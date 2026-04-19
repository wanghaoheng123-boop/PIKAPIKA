import SwiftUI
import PikaCore

struct PetOnboardingView: View {
    let onCreate: (Pet) -> Void

    @State private var name: String = ""
    @State private var species: String = "cat"
    @State private var traits: String = "playful, curious"
    @Environment(\.dismiss) private var dismiss

    private let speciesOptions = ["cat", "dog", "hamster", "fox", "rabbit"]

    var body: some View {
        Form {
            TextField("Name", text: $name)
            Picker("Species", selection: $species) {
                ForEach(speciesOptions, id: \.self) { Text($0.capitalized).tag($0) }
            }
            TextField("Personality (comma-separated)", text: $traits)
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
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
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 360)
    }
}
