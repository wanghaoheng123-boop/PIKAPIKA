import SwiftUI
import PikaCoreBase

/// UI-layer mood concept — maps to PetState for avatar animation.
/// Owned by SharedUI; PetBehaviorEngine drives actual PetState.
public enum PetMood: String, CaseIterable, Sendable {
    case happy
    case excited
    case idle
    case sleepy
    case sad

    public var displayName: String {
        switch self {
        case .happy:   return "Happy"
        case .excited: return "Excited"
        case .idle:    return "Idle"
        case .sleepy:  return "Sleepy"
        case .sad:     return "Sad"
        }
    }

    public var emoji: String {
        switch self {
        case .happy:   return "😊"
        case .excited: return "🤩"
        case .idle:    return "😺"
        case .sleepy:  return "😴"
        case .sad:     return "😿"
        }
    }

    public var color: Color {
        switch self {
        case .happy:   return .orange
        case .excited: return .yellow
        case .idle:    return PikaTheme.Palette.accentDeep
        case .sleepy:  return .indigo
        case .sad:     return .blue
        }
    }
}

extension PetState {
    /// Maps a UI-layer PetMood to a PetState for avatar animation.
    public static func from(mood: PetMood) -> PetState {
        switch mood {
        case .happy:   return .celebrating
        case .excited: return .celebrating
        case .idle:    return .idle
        case .sleepy:  return .sleeping
        case .sad:     return .sad
        }
    }
}
