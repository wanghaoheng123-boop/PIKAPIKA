import SwiftUI
import PikaCore

/// Circular progress ring showing progress within the current bond level.
public struct BondProgressRing: View {

    public let xp: Int
    public let diameter: CGFloat
    public let lineWidth: CGFloat

    @State private var shimmerOffset: CGFloat = -1

    public init(xp: Int, diameter: CGFloat = 64, lineWidth: CGFloat = 6) {
        self.xp = xp
        self.diameter = diameter
        self.lineWidth = lineWidth
    }

    public var body: some View {
        let level = BondLevel.from(xp: xp)
        let progress = BondLevel.progress(xp: xp)

        ZStack {
            Circle()
                .stroke(PikaTheme.Palette.xpTrack, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [
                            PikaTheme.Palette.accent,
                            PikaTheme.Palette.accentDeep,
                            PikaTheme.Palette.accent
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)

            shimmerOverlay(progress: progress)

            VStack(spacing: 0) {
                Text("\(level.rawValue)")
                    .font(PikaTheme.Typography.title)
                Text("LVL")
                    .font(PikaTheme.Typography.caption)
                    .foregroundStyle(PikaTheme.Palette.textMuted)
            }
        }
        .frame(width: diameter, height: diameter)
        .onAppear { startShimmer() }
        .accessibilityLabel("Bond level \(level.displayName), \(Int(progress * 100)) percent")
    }

    @ViewBuilder
    private func shimmerOverlay(progress: Double) -> some View {
        if progress > 0 {
            Circle()
                .trim(from: max(0, shimmerOffset - 0.15), to: shimmerOffset)
                .stroke(
                    Color.white.opacity(0.35),
                    style: StrokeStyle(lineWidth: lineWidth - 2, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }

    private func startShimmer() {
        shimmerOffset = -0.15
        withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
            shimmerOffset = 1.05
        }
    }
}
