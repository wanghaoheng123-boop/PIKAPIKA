import PhotosUI
import SwiftUI
import SwiftData
import PikaCore

struct AddPetSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AIClientHolder.self) private var aiHolder

    @State private var name = ""
    @State private var speciesPreset = "custom"
    @State private var speciesCustom = ""
    @State private var personalityPrompt = ""
    @State private var creatureDescription = ""
    @State private var pickedItem: PhotosPickerItem?
    @State private var uploadedJPEG: Data?
    @State private var isWorking = false
    @State private var errorText: String?

    private let speciesOptions = ["cat", "dog", "hamster", "custom"]

    private var resolvedSpecies: String {
        let c = speciesCustom.trimmingCharacters(in: .whitespacesAndNewlines)
        return c.isEmpty ? speciesPreset : c
    }

    private var canUseRemoteImage: Bool {
        aiHolder.hasRemoteAI && aiHolder.usagePolicy.allowRemoteImage
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pet") {
                    TextField("Name", text: $name)
                    Picker("Species template", selection: $speciesPreset) {
                        ForEach(speciesOptions, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Custom species name (optional)", text: $speciesCustom)
                        .textInputAutocapitalization(.never)
                }

                Section("Design your companion") {
                    TextField("Describe any creature (Pokémon-style, any animal, or something new)", text: $creatureDescription, axis: .vertical)
                        .lineLimit(3 ... 10)
                    Text("This text is saved on the pet and used for AI chat and optional image generation.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Personality") {
                    TextField("Tone or traits, comma-separated (optional)", text: $personalityPrompt, axis: .vertical)
                        .lineLimit(3 ... 6)
                }

                Section("Portrait") {
                    PhotosPicker(selection: $pickedItem, matching: .images, photoLibrary: .shared()) {
                        Label("Choose from Photos", systemImage: "photo.on.rectangle")
                    }
                    if uploadedJPEG != nil {
                        Text("Photo ready — will be saved when you create the pet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        Task { await analyzePhoto() }
                    } label: {
                        Label("Describe photo with AI (uses your API key)", systemImage: "text.viewfinder")
                    }
                    .disabled(isWorking || uploadedJPEG == nil || !canUseRemoteImage)

                    Button {
                        Task { await generatePortrait() }
                    } label: {
                        Label("Generate portrait with AI (DALL·E, uses your key)", systemImage: "wand.and.stars")
                    }
                    .disabled(isWorking || creatureDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !canUseRemoteImage)
                    if !canUseRemoteImage {
                        Text("Enable “Use remote AI for image design” in Settings and add an API key to use these tools.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorText {
                    Section {
                        Text(errorText)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
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
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isWorking)
                }
            }
            .onChange(of: pickedItem) { _, new in
                Task { await loadPhoto(new) }
            }
            .scrollContentBackground(.hidden)
            .background(PIKAPIKATheme.homeBackground.ignoresSafeArea())
            .tint(PIKAPIKATheme.accent)
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        await MainActor.run { errorText = nil }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    uploadedJPEG = data
                }
            }
        } catch {
            await MainActor.run { errorText = error.localizedDescription }
        }
    }

    private func analyzePhoto() async {
        guard let data = uploadedJPEG else { return }
        guard canUseRemoteImage else { return }
        await MainActor.run {
            isWorking = true
            errorText = nil
        }
        defer {
            Task { @MainActor in isWorking = false }
        }
        do {
            let text = try await aiHolder.client.describeImage(
                data,
                prompt: "Describe this creature in 2–4 vivid sentences for a virtual pet companion app. Focus on species, colors, mood, and anything distinctive."
            )
            await MainActor.run {
                if creatureDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    creatureDescription = text
                } else {
                    creatureDescription += "\n\n" + text
                }
            }
        } catch {
            await MainActor.run { errorText = error.localizedDescription }
        }
    }

    private func generatePortrait() async {
        let desc = creatureDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !desc.isEmpty else { return }
        guard canUseRemoteImage else { return }
        let vibe = await MainActor.run { resolvedSpecies }
        await MainActor.run {
            isWorking = true
            errorText = nil
        }
        defer {
            Task { @MainActor in isWorking = false }
        }
        do {
            let prompt = """
            Single full-body character portrait, centered, soft lighting, friendly expression, \
            transparent or simple gradient background, no text, no watermark, \
            digital illustration style. Creature concept: \(desc). Species vibe: \(vibe).
            """
            let data = try await aiHolder.client.generateImage(prompt: prompt, size: .square1024)
            guard !data.isEmpty else {
                await MainActor.run { errorText = "Image generation returned empty data." }
                return
            }
            await MainActor.run {
                uploadedJPEG = data
            }
        } catch {
            await MainActor.run { errorText = error.localizedDescription }
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
            species: resolvedSpecies,
            creationMethod: uploadedJPEG == nil ? "prompt" : "photo_or_ai",
            spriteAtlasPath: "placeholder",
            personalityTraits: traits,
            bondXP: 0,
            bondLevel: BondLevel.stranger.rawValue,
            creatureDescription: creatureDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            avatarImagePath: "",
            lastImagePrompt: nil
        )
        modelContext.insert(pet)
        do {
            try modelContext.save()
        } catch {
            errorText = error.localizedDescription
            modelContext.delete(pet)
            return
        }

        var hadSaveError = false
        if let jpeg = uploadedJPEG {
            do {
                let path = try PetImageStore.saveJPEG(jpeg, petId: pet.id, filename: "avatar.jpg")
                pet.avatarImagePath = path
                pet.lastImagePrompt = creatureDescription
            } catch {
                hadSaveError = true
                errorText = error.localizedDescription
            }
        }

        if hadSaveError {
            modelContext.delete(pet)
            do {
                try modelContext.save()
            } catch {
                errorText = error.localizedDescription
            }
            return
        }

        do {
            try modelContext.save()
        } catch {
            errorText = error.localizedDescription
            return
        }
        PetMemoryFileStore.syncFacts(petId: pet.id, petName: pet.name, facts: pet.memoryFacts)
        dismiss()
    }
}
