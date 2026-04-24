import SwiftUI

public struct TypingIndicator: View {
    @State private var animationPhase: Int = 0
    @State private var timer: Timer?

    public init() {}

    public var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(PikaTheme.Palette.accentDeep)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animationPhase == index ? 1.3 : 0.8)
                    .animation(.easeInOut(duration: 0.3), value: animationPhase)
            }
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { _ in
                withAnimation {
                    animationPhase = (animationPhase + 1) % 3
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
            animationPhase = 0
        }
        .frame(width: 28, height: 20)
        .accessibilityLabel("Typing indicator")
    }
}
