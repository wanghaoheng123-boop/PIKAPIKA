import SwiftUI

public struct ChatBubble: View {
    public enum Sender { case user, pet }

    public let text: String
    public let sender: Sender

    public init(text: String, sender: Sender) {
        self.text = text
        self.sender = sender
    }

    public var body: some View {
        HStack {
            if sender == .user { Spacer(minLength: PikaTheme.Spacing.xl) }
            Text(text)
                .font(PikaTheme.Typography.chat)
                .padding(.horizontal, PikaTheme.Spacing.md)
                .padding(.vertical, PikaTheme.Spacing.sm)
                .background(background)
                .foregroundStyle(foreground)
                .clipShape(RoundedRectangle(cornerRadius: PikaTheme.Radius.card, style: .continuous))
            if sender == .pet { Spacer(minLength: PikaTheme.Spacing.xl) }
        }
    }

    private var background: Color {
        sender == .user ? PikaTheme.Palette.accentDeep : PikaTheme.Palette.accent.opacity(0.25)
    }
    private var foreground: Color {
        sender == .user ? .white : PikaTheme.Palette.textPrimary
    }
}
