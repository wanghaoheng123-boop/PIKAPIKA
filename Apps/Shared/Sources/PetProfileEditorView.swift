import SwiftUI
import SwiftData
import PikaCore
import SharedUI

/// Edit a pet after creation (name, species, traits, lore, 3D preset, sound).
public struct PetProfileEditorView: View {
    let pet: Pet
    @Environment(\.dismiss) private var dismiss

    private let speciesOptions = ["cat", "dog", "hamster", "fox", "rabbit", "custom"]
    private let presetOptions: [(id: String, title: String)] = [
        ("auto", "Auto (from species)"),
        ("cat", "Cat (procedural)"),
        ("dog", "Dog (procedural)"),
        ("spark", "Spark mascot (original)"),
    ]

    public init(pet: Pet) {
        self.pet = pet
    }

    private var nameBinding: Binding<String> {
        Binding(get: { pet.name }, set: { pet.name = $0 })
    }

    private var speciesBinding: Binding<String> {
        Binding(get: { pet.species }, set: { pet.species = $0 })
    }

    private var traitsTextBinding: Binding<String> {
        Binding(
            get: { pet.personalityTraits.joined(separator: ", ") },
            set: { new in
                pet.personalityTraits = new
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .map { String($0) }
            }
        )
    }

    private var creatureBinding: Binding<String> {
        Binding(get: { pet.creatureDescription }, set: { pet.creatureDescription = $0 })
    }

    private var presetBinding: Binding<String> {
        Binding(
            get: { pet.visualModelPreset.isEmpty ? "auto" : pet.visualModelPreset },
            set: { pet.visualModelPreset = $0 }
        )
    }

    private var soundEnabledBinding: Binding<Bool> {
        Binding(get: { pet.soundEnabled }, set: { pet.soundEnabled = $0 })
    }

    private var soundProfileBinding: Binding<String> {
        Binding(get: { pet.soundProfileKey }, set: { pet.soundProfileKey = $0 })
    }

    public var body: some View {
        Form {
            Section("Basics") {
                TextField("Name", text: nameBinding)
                Picker("Species", selection: speciesBinding) {
                    ForEach(speciesOptions, id: \.self) { s in
                        Text(s.capitalized).tag(s)
                    }
                }
                TextField("Personality (comma-separated)", text: traitsTextBinding, axis: .vertical)
                    .lineLimit(2 ... 6)
            }

            Section("Character") {
                TextField("Creature description", text: creatureBinding, axis: .vertical)
                    .lineLimit(3 ... 10)
            }

            Section("3D look") {
                Picker("Preset", selection: presetBinding) {
                    ForEach(presetOptions, id: \.id) { row in
                        Text(row.title).tag(row.id)
                    }
                }
                Text("“Spark” is an original electric-mascot style, not third-party IP. Custom USDZ: use PIKAPIKA pet customization when available.")
                    .font(PikaTheme.Typography.caption)
                    .foregroundStyle(PikaTheme.Palette.textMuted)
            }

            Section("Sound") {
                Toggle("Sound enabled", isOn: soundEnabledBinding)
                TextField("Sound profile", text: soundProfileBinding)
            }
        }
        .navigationTitle("Edit pet")
        .onAppear {
            if pet.visualModelPreset.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                pet.visualModelPreset = "auto"
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
