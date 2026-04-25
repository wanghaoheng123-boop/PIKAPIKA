import SwiftUI

public struct TypingIndicator: View {
<<<<<<< HEAD
    @State private var isAnimating = false
=======
    @State private var phase: Double = 0
>>>>>>> ec0be87 (chore: checkpoint autonomous quality and orchestration updates)

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
<<<<<<< HEAD
            withAnimation(
                Animation
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
=======
            phase = 1
        }
        .animation(
            .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
            value: phase
        )
>>>>>>> ec0be87 (chore: checkpoint autonomous quality and orchestration updates)
        .accessibilityLabel("Typing indicator")
    }

    private func animatingScale(for index: Int) -> CGFloat {
<<<<<<< HEAD
        guard isAnimating else { return 0.8 }
        let phase = (index - 0) % 3
        switch phase {
        case 0: return 1.3
        case 1: return 0.8
        case 2: return 1.0
        default: return 0.8
        }
=======
        let baseline: CGFloat = 0.8
        let delta: CGFloat = 0.35
        let perDotDelay = Double(index) * 0.15
        let wave = sin((phase - perDotDelay) * .pi)
        return baseline + max(0, CGFloat(wave)) * delta
>>>>>>> ec0be87 (chore: checkpoint autonomous quality and orchestration updates)
    }
}
