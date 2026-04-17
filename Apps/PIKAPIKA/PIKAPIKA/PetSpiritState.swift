import SwiftUI
import PikaCore

/// “Spirit” — emotional state surfaced in UI so the pet feels alive (QQ penguin–style mood, modernized).
enum PetSpiritState: String, CaseIterable {
    case radiant
    case playful
    case curious
    case cozy
    case wistful
    case longing

    var title: String {
        switch self {
        case .radiant: return "Spirit: Radiant"
        case .playful: return "Spirit: Playful"
        case .curious: return "Spirit: Curious"
        case .cozy: return "Spirit: Cozy"
        case .wistful: return "Spirit: Wistful"
        case .longing: return "Spirit: Longing for you"
        }
    }

    var shortTitle: String {
        switch self {
        case .radiant: return "Radiant"
        case .playful: return "Playful"
        case .curious: return "Curious"
        case .cozy: return "Cozy"
        case .wistful: return "Wistful"
        case .longing: return "Longing"
        }
    }

    var emoji: String {
        switch self {
        case .radiant: return "✨"
        case .playful: return "🎈"
        case .curious: return "👀"
        case .cozy: return "🌙"
        case .wistful: return "💭"
        case .longing: return "💔"
        }
    }

    var subtitle: String {
        switch self {
        case .radiant:
            return "Your bond shines — they’re fully here with you."
        case .playful:
            return "Ready for mischief, jokes, and little adventures."
        case .curious:
            return "Watching, learning, wondering what you’ll do next."
        case .cozy:
            return "Quiet and calm — check in when you can."
        case .wistful:
            return "They’ve been waiting. A quick hello means a lot."
        case .longing:
            return "They miss you. Come back and share a moment."
        }
    }

    var pillColors: [Color] {
        switch self {
        case .radiant:
            return [Color(red: 1.0, green: 0.85, blue: 0.4), PIKAPIKATheme.accent.opacity(0.85)]
        case .playful:
            return [PIKAPIKATheme.accent, PIKAPIKATheme.accentSecondary]
        case .curious:
            return [PIKAPIKATheme.accentSecondary, Color.cyan.opacity(0.7)]
        case .cozy:
            return [Color.indigo.opacity(0.55), Color.purple.opacity(0.45)]
        case .wistful:
            return [Color.gray.opacity(0.45), Color.blue.opacity(0.35)]
        case .longing:
            return [Color.purple.opacity(0.5), Color.pink.opacity(0.45)]
        }
    }

    static func evaluate(for pet: Pet) -> PetSpiritState {
        let hoursAway = Date().timeIntervalSince(pet.lastInteractedAt) / 3600
        let xp = pet.bondXP

        if hoursAway > 72 { return .longing }
        if hoursAway > 36 { return .wistful }
        if hoursAway > 12 { return .cozy }
        if xp >= 1_200 { return .radiant }
        if xp >= 200 { return .playful }
        return .curious
    }
}
