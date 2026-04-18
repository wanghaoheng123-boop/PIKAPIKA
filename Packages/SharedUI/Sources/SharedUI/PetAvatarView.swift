import SwiftUI
import PikaCore

/// Placeholder avatar view. The production implementation will host a Lottie
/// animation (or SpriteKit scene) driven by `PetState`. For now we render an
/// emoji appropriate to the species so the rest of the UI is testable.
public struct PetAvatarView: View {

    public let pet: Pet
    public let state: PetState
    public let size: CGFloat

    public init(pet: Pet, state: PetState = .idle, size: CGFloat = 120) {
        self.pet = pet
        self.state = state
        self.size = size
    }

    public var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.7))
            .frame(width: size, height: size)
            .background(
                Circle().fill(PikaTheme.Palette.accent.opacity(0.18))
            )
            .overlay(
                Circle().stroke(PikaTheme.Palette.accent, lineWidth: 2)
            )
            .scaleEffect(scaleForState)
            .animation(.spring(duration: 0.4), value: state.animationKey)
            .accessibilityLabel("\(pet.name), \(state.displayName)")
    }

    private var emoji: String {
        switch pet.species.lowercased() {
        case "cat":     return "🐱"
        case "dog":     return "🐶"
        case "hamster": return "🐹"
        case "fox":     return "🦊"
        case "rabbit":  return "🐰"
        default:        return "🐾"
        }
    }

    private var scaleForState: CGFloat {
        switch state {
        case .celebrating: return 1.15
        case .sleeping:    return 0.92
        case .sad:         return 0.94
        default:           return 1.0
        }
    }
}
