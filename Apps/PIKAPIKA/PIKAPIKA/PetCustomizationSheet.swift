import SwiftUI
import UniformTypeIdentifiers
import SceneKit
import PikaCore

struct PetCustomizationSheet: View {
    @Bindable var pet: Pet
    var onModelImported: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showImporter = false
    @State private var errorText: String?

    private let soundProfiles = ["cute", "soft", "playful", "robot"]

    var body: some View {
        NavigationStack {
            Form {
                Section("3D model (USDZ)") {
                    if pet.modelUSDZPath.isEmpty {
                        Text("No custom model yet. The app uses card-avatar mode.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(pet.modelUSDZPath)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Button("Import USDZ model") { showImporter = true }
                }

                Section("3D preset (no file)") {
                    Picker("Look", selection: $pet.visualModelPreset) {
                        Text("Auto").tag("auto")
                        Text("Cat").tag("cat")
                        Text("Dog").tag("dog")
                        Text("Spark mascot").tag("spark")
                    }
                    Text("Used when no USDZ is imported. “Spark” is an original electric-mascot style.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Character sound") {
                    Toggle("Enable pet sounds", isOn: $pet.soundEnabled)
                    Picker("Sound style", selection: $pet.soundProfileKey) {
                        ForEach(soundProfiles, id: \.self) { key in
                            Text(key.capitalized).tag(key)
                        }
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
            .navigationTitle("Customize pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [UTType(filenameExtension: "usdz") ?? .data],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    do {
                        let maxBytes = 20 * 1024 * 1024
                        let hasScope = url.startAccessingSecurityScopedResource()
                        defer {
                            if hasScope { url.stopAccessingSecurityScopedResource() }
                        }
                        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
                        if let bytes = attrs[.size] as? Int64, bytes > Int64(maxBytes) {
                            throw NSError(domain: "PetCustomization", code: 1, userInfo: [NSLocalizedDescriptionKey: "USDZ is too large. Please use a file under 20 MB."])
                        }
                        let data = try Data(contentsOf: url)
                        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".usdz")
                        try data.write(to: temp, options: .atomic)
                        defer { try? FileManager.default.removeItem(at: temp) }
                        guard (try? SCNScene(url: temp, options: nil)) != nil else {
                            throw NSError(domain: "PetCustomization", code: 2, userInfo: [NSLocalizedDescriptionKey: "This USDZ could not be loaded. Try another model file."])
                        }
                        let relative = try PetImageStore.saveUSDZ(data, petId: pet.id, filename: "pet.usdz")
                        pet.modelUSDZPath = relative
                        onModelImported(relative)
                    } catch {
                        errorText = error.localizedDescription
                    }
                case .failure(let error):
                    errorText = error.localizedDescription
                }
            }
        }
    }
}
