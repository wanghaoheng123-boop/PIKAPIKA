import Foundation
import UIKit

/// On-disk portrait storage for each pet (user upload or AI-generated).
enum PetImageStore {
    private static let rootFolder = "PIKAPIKA/Pets"

    static func documentsRoot() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func petDirectoryURL(for petId: UUID) throws -> URL {
        let url = documentsRoot().appendingPathComponent(rootFolder, isDirectory: true)
            .appendingPathComponent(petId.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Returns a path relative to Documents (for `Pet.avatarImagePath`).
    static func relativePath(petId: UUID, filename: String) -> String {
        "\(rootFolder)/\(petId.uuidString)/\(filename)"
    }

    /// Saves `image` as a high-quality JPEG (0.88) and returns the relative path.
    static func saveJPEG(_ image: UIImage, petId: UUID, filename: String = "avatar.jpg", quality: CGFloat = 0.88) throws -> String {
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw NSError(domain: "PetImageStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create JPEG data"])
        }
        return try saveJPEG(data, petId: petId, filename: filename)
    }

    /// Saves raw JPEG `data` atomically and returns the relative path.
    static func saveJPEG(_ data: Data, petId: UUID, filename: String = "avatar.jpg") throws -> String {
        let dir = try petDirectoryURL(for: petId)
        let url = dir.appendingPathComponent(filename, isDirectory: false)
        try data.write(to: url, options: .atomic)
        return relativePath(petId: petId, filename: filename)
    }



    static func saveUSDZ(_ data: Data, petId: UUID, filename: String = "pet.usdz") throws -> String {
        let dir = try petDirectoryURL(for: petId)
        let url = dir.appendingPathComponent(filename, isDirectory: false)
        try data.write(to: url, options: .atomic)
        return relativePath(petId: petId, filename: filename)
    }

    static func localURL(relativePath: String) -> URL? {
        guard !relativePath.isEmpty else { return nil }
        let url = documentsRoot().appendingPathComponent(relativePath, isDirectory: false)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    static func loadImage(relativePath: String) -> UIImage? {
        guard !relativePath.isEmpty else { return nil }
        let url = documentsRoot().appendingPathComponent(relativePath, isDirectory: false)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    static func deletePetFolder(petId: UUID) {
        let url = documentsRoot().appendingPathComponent(rootFolder, isDirectory: true)
            .appendingPathComponent(petId.uuidString, isDirectory: true)
        try? FileManager.default.removeItem(at: url)
    }
}
