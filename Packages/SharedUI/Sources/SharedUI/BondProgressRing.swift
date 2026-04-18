import SwiftUI
import PikaCore

/// Circular progress ring showing progress within the current bond level.
public struct BondProgressRing: View {

    public let xp: Int
    public let diameter: CGFloat
    public let lineWidth: CGFloat

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
                        colors: [PikaTheme.Palette.accent, PikaTheme.Palette.accentDeep],
                        startPoint: .top, endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)
            VStack(spacing: 0) {
                Text("\(level.rawValue)")
                    .font(PikaTheme.Typography.title)
                Text("LVL")
                    .font(PikaTheme.Typography.caption)
                    .foregroundStyle(PikaTheme.Palette.textMuted)
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityLabel("Bond level \(level.displayName), \(Int(progress * 100)) percent")
    }
}
