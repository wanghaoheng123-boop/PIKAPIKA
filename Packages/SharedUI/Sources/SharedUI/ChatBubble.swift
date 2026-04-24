import SwiftUI

public struct ChatBubble: View {
    public enum Sender { case user, pet }

    public let text: String
    public let sender: Sender
    public let timestamp: Date?

    public init(text: String, sender: Sender, timestamp: Date? = nil) {
        self.text = text
        self.sender = sender
        self.timestamp = timestamp
    }

    public var body: some View {
        VStack(alignment: sender == .user ? .trailing : .leading, spacing: 2) {
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
            if let timestamp {
                Text(timestampText(for: timestamp))
                    .font(.system(size: 10))
                    .foregroundStyle(PikaTheme.Palette.textMuted)
                    .padding(.horizontal, sender == .user ? PikaTheme.Spacing.xl + PikaTheme.Spacing.sm : PikaTheme.Spacing.sm)
            }
        }
    }

    private var background: Color {
        sender == .user ? PikaTheme.Palette.accentDeep : PikaTheme.Palette.accent.opacity(0.25)
    }
    private var foreground: Color {
        sender == .user ? .white : PikaTheme.Palette.textPrimary
    }

    private func timestampText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
