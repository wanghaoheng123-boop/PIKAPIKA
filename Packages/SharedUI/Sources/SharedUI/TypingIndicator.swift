import SwiftUI

public struct TypingIndicator: View {
    @State private var phase: Double = 0

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
            phase = 1
        }
        .animation(
            .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
            value: phase
        )
        .accessibilityLabel("Typing indicator")
    }

    private func animatingScale(for index: Int) -> CGFloat {
        let baseline: CGFloat = 0.8
        let delta: CGFloat = 0.35
        let perDotDelay = Double(index) * 0.15
        let wave = sin((phase - perDotDelay) * .pi)
        return baseline + max(0, CGFloat(wave)) * delta
    }
}
