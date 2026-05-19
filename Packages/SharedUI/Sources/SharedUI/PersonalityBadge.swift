import SwiftUI

public struct PersonalityBadge: View {
    public let trait: String

    public init(trait: String) { self.trait = trait }

    public var body: some View {
        Text(trait)
            .font(PikaTheme.Typography.caption.weight(.medium))
            .padding(.horizontal, PikaTheme.Spacing.sm + 2)
            .padding(.vertical, PikaTheme.Spacing.xs + 1)
            .background(
                Capsule()
                    .fill(PikaTheme.Palette.accent.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(PikaTheme.Palette.accent.opacity(0.35), lineWidth: 0.75)
                    )
            )
            .foregroundStyle(PikaTheme.Palette.accentDeep)
    }
}
