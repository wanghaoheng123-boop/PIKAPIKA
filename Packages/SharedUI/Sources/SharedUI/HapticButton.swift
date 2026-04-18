import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Primary action button with haptic feedback on iOS.
public struct HapticButton<Label: View>: View {

    private let action: () -> Void
    private let label: Label

    public init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
    }

    public var body: some View {
        Button {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            #endif
            action()
        } label: {
            label
                .font(PikaTheme.Typography.body.weight(.semibold))
                .padding(.horizontal, PikaTheme.Spacing.lg)
                .padding(.vertical, PikaTheme.Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(PikaTheme.Palette.accentDeep)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: PikaTheme.Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
