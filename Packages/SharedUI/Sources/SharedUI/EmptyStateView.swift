import SwiftUI

public struct EmptyStateView: View {
    public let title: String
    public let message: String
    public let icon: String
    public let actionTitle: String?
    public let action: (() -> Void)?

    public init(
        title: String,
        message: String,
        icon: String = "pawprint.fill",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: PikaTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(PikaTheme.Palette.accent.opacity(0.12))
                    .frame(width: 120, height: 120)
                Circle()
                    .fill(PikaTheme.Palette.accent.opacity(0.2))
                    .frame(width: 80, height: 80)
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(PikaTheme.Palette.accentDeep)
            }
            .padding(.bottom, PikaTheme.Spacing.sm)

            VStack(spacing: PikaTheme.Spacing.sm) {
                Text(title)
                    .font(PikaTheme.Typography.title)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(PikaTheme.Typography.body)
                    .foregroundStyle(PikaTheme.Palette.textMuted)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(PikaTheme.Typography.body.weight(.semibold))
                        .padding(.horizontal, PikaTheme.Spacing.xl)
                        .padding(.vertical, PikaTheme.Spacing.sm)
                        .background(PikaTheme.Palette.accentDeep)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(PikaTheme.Spacing.xl)
        .accessibilityElement(children: .combine)
    }
}
