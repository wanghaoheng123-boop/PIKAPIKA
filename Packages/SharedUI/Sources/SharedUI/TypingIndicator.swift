import SwiftUI

public struct TypingIndicator: View {
    @State private var dotCount = 0

    public init() {}

    public var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(PikaTheme.Palette.accentDeep)
                    .frame(width: 6, height: 6)
                    .scaleEffect(dotCount == index ? 1.3 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.18),
                        value: dotCount
                    )
            }
        }
        .onAppear {
            dotCount = 1
        }
        .frame(width: 28, height: 20)
        .accessibilityLabel("Typing indicator")
    }
}
