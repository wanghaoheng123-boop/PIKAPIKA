import SwiftUI
import UniformTypeIdentifiers
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
                        let data = try Data(contentsOf: url)
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
