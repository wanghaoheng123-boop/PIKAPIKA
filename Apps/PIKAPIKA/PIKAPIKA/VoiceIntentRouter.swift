import Foundation

enum VoiceIntent {
    case pet
    case feed
    case play
    case move(String)
    case openMemories
    case ask(String)
}

enum VoiceIntentRouter {
    static func parse(_ text: String) -> VoiceIntent? {
        let raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        let lower = raw.lowercased()

        if lower == "pet" || lower == "pet now" { return .pet }
        if lower == "feed" || lower.contains("feed pet") { return .feed }
        if lower == "play" || lower.contains("play with pet") { return .play }
        if lower == "open memories" || lower == "memories" { return .openMemories }
        if lower.hasPrefix("move ") {
            let name = raw.dropFirst(5).trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty { return .move(name) }
        }
        if lower.hasPrefix("ask ") {
            let q = raw.dropFirst(4).trimmingCharacters(in: .whitespacesAndNewlines)
            if !q.isEmpty { return .ask(q) }
        }
        return nil
    }
}
