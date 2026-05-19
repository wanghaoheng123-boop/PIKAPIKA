import Foundation
import PikaCore

/// OpenViking-style per-pet mirror on disk: small, human-readable index + JSONL for export/debugging.
/// SwiftData remains the source of truth; this is a structured snapshot.
enum PetMemoryFileStore {
    private static let rootFolder = "PIKAPIKA_MEMORY"
    private static let mirrorEnabledKey = "com.pikapika.PIKAPIKA.memoryMirrorEnabled"

    private static func baseURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(rootFolder, isDirectory: true)
    }

    private static func petURL(petId: UUID) -> URL {
        baseURL().appendingPathComponent(petId.uuidString, isDirectory: true)
    }

    /// Removes all plaintext mirror exports when the user opts out.
    /// SwiftData remains the source of truth and is not affected.
    static func purgeAllMirrors() -> Bool {
        let base = baseURL()
        guard FileManager.default.fileExists(atPath: base.path) else { return true }
        do {
            try FileManager.default.removeItem(at: base)
            return true
        } catch {
            return false
        }
    }

    static func syncFacts(petId: UUID, petName: String, facts: [PetMemoryFact]) {
        guard UserDefaults.standard.bool(forKey: mirrorEnabledKey) else { return }
        let dir = petURL(petId: petId)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        applyDirectoryProtection(at: dir)
        let sorted = facts.sorted { a, b in
            if a.importance != b.importance { return a.importance > b.importance }
            return a.createdAt > b.createdAt
        }
        let index = makeIndexMarkdown(petName: petName, facts: sorted)
        let indexURL = dir.appendingPathComponent("index.md", isDirectory: false)
        try? index.write(to: indexURL, atomically: true, encoding: .utf8)
        applyFileProtection(at: indexURL)

        let enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        var lines = Data()
        for f in sorted {
            let row = FactLine(
                id: f.id.uuidString,
                content: f.content,
                category: f.category,
                importance: f.importance,
                importanceLabel: priorityLabel(f.importance),
                created: ISO8601DateFormatter().string(from: f.createdAt),
                source: f.source
            )
            if let chunk = try? enc.encode(row) {
                lines.append(chunk)
                lines.append(Data([0x0A]))
            }
        }
        let jsonlURL = dir.appendingPathComponent("facts.jsonl", isDirectory: false)
        try? lines.write(to: jsonlURL, options: .atomic)
        applyFileProtection(at: jsonlURL)
    }

    private static func makeIndexMarkdown(petName: String, facts: [PetMemoryFact]) -> String {
        var s = "# \(petName) — memory index\n\n"
        s += "Priority: P0 critical, P1 useful, P2 nice-to-have.\n\n"
        for f in facts.prefix(24) {
            s += "- [\(priorityLabel(f.importance))] **\(f.category)**: \(f.content)\n"
        }
        if facts.count > 24 {
            s += "\n_…and \(facts.count - 24) more in facts.jsonl._\n"
        }
        return s
    }

    private static func priorityLabel(_ i: Int) -> String {
        switch i {
        case 2: return "P0"
        case 1: return "P1"
        default: return "P2"
        }
    }

    private static func applyDirectoryProtection(at url: URL) {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? (url as NSURL).setResourceValue(URLFileProtection.completeUntilFirstUserAuthentication, forKey: .fileProtectionKey)
        try? url.setResourceValues(values)
    }

    private static func applyFileProtection(at url: URL) {
        try? (url as NSURL).setResourceValue(URLFileProtection.completeUntilFirstUserAuthentication, forKey: .fileProtectionKey)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
    }

    private struct FactLine: Encodable {
        let id: String
        let content: String
        let category: String
        let importance: Int
        let importanceLabel: String
        let created: String
        let source: String
    }
}
