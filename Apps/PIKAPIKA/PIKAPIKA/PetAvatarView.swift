import SwiftUI
import UIKit
import PikaCore

/// Visual pet: 3D stage with optional portrait texture, or emoji fallback until an image is set.
struct PetAvatarView: View {
    let pet: Pet
    var speechBubble: String?
    var avatarImage: UIImage?
    var actionName: String
    var actionTick: Int
    var onTapPet: () -> Void

    @State private var bounceOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            PIKAPIKATheme.accent.opacity(0.38),
                            PIKAPIKATheme.accentSecondary.opacity(0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                }
                .frame(height: 300)
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)

            if let speechBubble, !speechBubble.isEmpty {
                Text(speechBubble)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 20)
                    .offset(y: 12)
            }

            PetScene3DView(
                image: avatarImage,
                modelURL: PetImageStore.localURL(relativePath: pet.modelUSDZPath),
                speciesEmoji: Self.speciesEmoji(pet.species),
                actionName: actionName,
                actionTick: actionTick
            )
            .frame(height: 280)
            .padding(.top, (speechBubble?.isEmpty ?? true) ? 48 : 80)
            .offset(y: bounceOffset)
            .contentShape(Rectangle())
            .onTapGesture(perform: handleTap)
        }
        .frame(maxWidth: .infinity)
    }

    private func handleTap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onTapPet()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.45)) {
            bounceOffset = -22
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                bounceOffset = 0
            }
        }
    }

    static func speciesEmoji(_ species: String) -> String {
        switch species.lowercased() {
        case "cat": return "🐱"
        case "dog": return "🐶"
        case "hamster": return "🐹"
        case "custom": return "✨"
        default: return "🐾"
        }
    }
}
