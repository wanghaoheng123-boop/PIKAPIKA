import SwiftUI

public struct TypingIndicator: View {
    @State private var isAnimating = false

    public init() {}

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(PikaTheme.Palette.accentDeep)
                    .frame(width: 7, height: 7)
                    .scaleEffect(animatingScale(for: index))
            }
        }
        .frame(width: 32, height: 20)
        .onAppear {
            withAnimation(
                Animation
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
        .accessibilityLabel("Typing indicator")
    }

    private func animatingScale(for index: Int) -> CGFloat {
        guard isAnimating else { return 0.8 }
        let phase = (index - 0) % 3
        switch phase {
        case 0: return 1.3
        case 1: return 0.8
        case 2: return 1.0
        default: return 0.8
        }
    }
}
