import SwiftUI

public struct PersonalityBadge: View {
    public let trait: String

    public init(trait: String) { self.trait = trait }

    public var body: some View {
        Text(trait)
            .font(PikaTheme.Typography.caption)
            .padding(.horizontal, PikaTheme.Spacing.sm)
            .padding(.vertical, PikaTheme.Spacing.xs)
            .background(PikaTheme.Palette.accent.opacity(0.2))
            .foregroundStyle(PikaTheme.Palette.accentDeep)
            .clipShape(Capsule())
    }
}
