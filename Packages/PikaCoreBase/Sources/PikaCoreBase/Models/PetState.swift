import Foundation

/// The current behavioral/animation state of the pet.
/// Driven by PetStateMachine and consumed by AnimationDirector.
public enum PetState: Equatable, Sendable {
    case idle
    case sleeping
    case typing(intensity: TypingIntensity)
    case reacting(context: AppContext)
    case chatting
    case eating
    case celebrating        // Bond level milestone unlock
    case sad                // Low interaction / coming back from long absence
    case curious            // Looking around; triggered after a context switch

    public var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .sleeping: return "Sleeping"
        case .typing(let intensity): return "Typing (\(intensity.rawValue))"
        case .reacting(let ctx): return "Reacting to \(ctx.displayName)"
        case .chatting: return "Chatting"
        case .eating: return "Eating"
        case .celebrating: return "Celebrating"
        case .sad: return "Sad"
        case .curious: return "Curious"
        }
    }

    /// The SpriteKit animation key to play for this state.
    public var animationKey: String {
        switch self {
        case .idle: return "idle_loop"
        case .sleeping: return "sleep_loop"
        case .typing(.slow): return "type_slow"
        case .typing(.medium): return "type_medium"
        case .typing(.fast): return "type_fast"
        case .typing(.frantic): return "type_frantic"
        case .reacting(let ctx): return ctx.animationKey
        case .chatting: return "chat_bubble"
        case .eating: return "eat_loop"
        case .celebrating: return "celebrate_once"
        case .sad: return "sad_loop"
        case .curious: return "curious_loop"
        }
    }
}

/// Typing speed classification that maps to different animation speeds.
public enum TypingIntensity: String, Equatable, Sendable {
    case slow       // < 20 kpm
    case medium     // 20–60 kpm
    case fast       // 60–100 kpm
    case frantic    // > 100 kpm

    public static func classify(keystrokesPerMinute: Double) -> TypingIntensity {
        switch keystrokesPerMinute {
        case ..<20: return .slow
        case 20..<60: return .medium
        case 60..<100: return .fast
        default: return .frantic
        }
    }
}

/// The application context the pet reacts to.
/// Maps bundle IDs to personality-flavored animations.
public enum AppContext: String, Equatable, Sendable, CaseIterable {
    case coding         // Xcode, VSCode, IntelliJ
    case browsing       // Safari, Chrome, Firefox
    case music          // Spotify, Apple Music
    case messaging      // Slack, Teams, Messages, Discord
    case documents      // Pages, Word, Google Docs
    case terminal       // Terminal, iTerm2
    case design         // Figma, Sketch, Photoshop
    case video          // YouTube, Netflix, Zoom
    case email          // Mail, Outlook
    case unknown

    public var displayName: String { rawValue.capitalized }

    public var animationKey: String {
        switch self {
        case .coding:     return "react_code"
        case .browsing:   return "react_browse"
        case .music:      return "react_dance"
        case .messaging:  return "react_chat"
        case .documents:  return "react_write"
        case .terminal:   return "react_terminal"
        case .design:     return "react_art"
        case .video:      return "react_watch"
        case .email:      return "react_email"
        case .unknown:    return "idle_loop"
        }
    }

    public var systemPromptHint: String {
        switch self {
        case .coding:    return "The user is writing code. Be technical and encouraging."
        case .browsing:  return "The user is browsing the web. Be curious and inquisitive."
        case .music:     return "Music is playing! Feel free to be expressive and dancey."
        case .messaging: return "The user is in a conversation. Be social and warm."
        case .documents: return "The user is writing. Be thoughtful and literary."
        case .terminal:  return "The user is in the terminal. Match their focused energy."
        case .design:    return "The user is designing something. Be aesthetically aware."
        case .video:     return "The user is watching video. You can relax and be cozy."
        case .email:     return "The user is handling emails. Be concise and professional."
        case .unknown:   return "Be your natural self."
        }
    }
}
