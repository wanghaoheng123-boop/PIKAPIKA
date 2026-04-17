import SwiftUI
import UIKit
import PikaCore

// MARK: - Section header

struct PikaSectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Spirit + bond strip

struct SpiritBondStrip: View {
    let pet: Pet
    let spirit: PetSpiritState

    private var level: BondLevel { BondLevel.from(xp: pet.bondXP) }
    private var progress: Double { BondLevel.progress(xp: pet.bondXP) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Text(spirit.emoji)
                    .font(.system(size: 36))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(spirit.shortTitle)
                        .font(.headline)
                    Text(spirit.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Label("\(pet.streakCount)d", systemImage: "flame.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                    Text("streak")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Streak \(pet.streakCount) days")
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(level.displayName)
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Text("\(pet.bondXP) XP")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.08))
                            .frame(height: 8)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [PIKAPIKATheme.accent, PIKAPIKATheme.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, geo.size.width * progress), height: 8)
                    }
                }
                .frame(height: 8)
                .accessibilityLabel("Bond progress")
                .accessibilityValue("\(Int(progress * 100)) percent to next level")
            }
        }
        .padding(PikaMetrics.cardPadding)
        .background {
            RoundedRectangle(cornerRadius: PIKAPIKATheme.cornerLarge, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: spirit.pillColors.map { $0.opacity(0.22) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: PIKAPIKATheme.cornerLarge, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                }
        }
    }
}

// MARK: - Pet row card (home)

struct PetHomeCard: View {
    let pet: Pet
    let spirit: PetSpiritState
    var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: PIKAPIKATheme.cornerMedium, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: spirit.pillColors.map { $0.opacity(0.35) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                if let img = thumbnail {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    Text(PetAvatarView.speciesEmoji(pet.species))
                        .font(.system(size: 32))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(pet.name)
                        .font(.headline)
                    Spacer()
                    Text(spirit.emoji)
                        .font(.caption)
                }
                Text(BondLevel.from(xp: pet.bondXP).displayName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Label("\(pet.streakCount)d", systemImage: "flame.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(spirit.shortTitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(PikaMetrics.cardPadding)
        .background {
            RoundedRectangle(cornerRadius: PIKAPIKATheme.cornerLarge, style: .continuous)
                .fill(.background)
                .shadow(color: PIKAPIKATheme.shadowSoft, radius: 10, x: 0, y: 3)
        }
        .overlay {
            RoundedRectangle(cornerRadius: PIKAPIKATheme.cornerLarge, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }
}

// MARK: - Primary / secondary buttons (consistent tap targets)

struct PikaProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: PIKAPIKATheme.cornerMedium, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [PIKAPIKATheme.accent, PIKAPIKATheme.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(configuration.isPressed ? 0.85 : 1)
            }
            .foregroundStyle(.white)
    }
}

struct PikaSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background {
                RoundedRectangle(cornerRadius: PIKAPIKATheme.cornerMedium, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .opacity(configuration.isPressed ? 0.8 : 1)
            }
    }
}
