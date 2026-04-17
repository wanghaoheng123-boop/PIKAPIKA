import SwiftUI
import SwiftData
import PikaCore

struct AddPetSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var species = "cat"
    @State private var personalityPrompt = ""

    private let speciesOptions = ["cat", "dog", "hamster", "custom"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Pet") {
                    TextField("Name", text: $name)
                    Picker("Species", selection: $species) {
                        ForEach(speciesOptions, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section("Personality") {
                    TextField("Describe tone or traits (optional)", text: $personalityPrompt, axis: .vertical)
                        .lineLimit(3 ... 6)
                }
            }
            .navigationTitle("New pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { savePet() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func savePet() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let traits: [String]
        if personalityPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            traits = []
        } else {
            traits = personalityPrompt
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .map { String($0) }
        }

        let pet = Pet(
            name: trimmed,
            species: species,
            creationMethod: "prompt",
            spriteAtlasPath: "placeholder",
            personalityTraits: traits,
            bondXP: 0,
            bondLevel: BondLevel.stranger.rawValue
        )
        modelContext.insert(pet)
        dismiss()
    }
}
