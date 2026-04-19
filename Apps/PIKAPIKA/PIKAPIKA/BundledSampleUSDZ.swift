import Foundation
import SceneKit
import PikaCore

/// Tiny built-in USDZ models so users can preview real SceneKit USDZ loading before importing their own files.
enum BundledSampleUSDZ: String, CaseIterable, Identifiable {
    case cat = "PikaSampleCat"
    case dog = "PikaSampleDog"
    case spark = "PikaSampleSpark"

    var id: String { rawValue }

    var bundleBaseName: String { rawValue }

    var title: String {
        switch self {
        case .cat: return "Sample cat (USDZ)"
        case .dog: return "Sample dog (USDZ)"
        case .spark: return "Sample spark (USDZ)"
        }
    }

    /// Copies the bundled asset into the pet’s Documents folder (same layout as **Import USDZ**).
    func install(for petId: UUID) throws -> String {
        guard
            let url = Bundle.main.url(
                forResource: bundleBaseName,
                withExtension: "usdz",
                subdirectory: "SamplePets"
            ) ?? Bundle.main.url(forResource: bundleBaseName, withExtension: "usdz")
        else {
            throw NSError(
                domain: "BundledSampleUSDZ",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Sample model is missing from the app bundle."]
            )
        }
        let data = try Data(contentsOf: url)
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".usdz")
        try data.write(to: temp, options: .atomic)
        defer { try? FileManager.default.removeItem(at: temp) }
        guard (try? SCNScene(url: temp, options: nil)) != nil else {
            throw NSError(
                domain: "BundledSampleUSDZ",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "This sample file could not be opened as a 3D scene."]
            )
        }
        return try PetImageStore.saveUSDZ(data, petId: petId, filename: "pet.usdz")
    }
}
