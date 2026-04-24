import SwiftUI

/// Design tokens. Keep this the single source of truth for colors / spacing /
/// typography so iOS and macOS renders stay consistent.
public enum PikaTheme {

    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 40
    }

    public enum Radius {
        public static let card: CGFloat = 14
        public static let pill: CGFloat = 999
    }

    public enum Palette {
        // TODO (Medium): Replace with Color("Accent") from Assets.xcassets Color Set
        // with Light variant: #FA6B73, Dark variant: #FF8A92
        public static let accent = Color(red: 1.00, green: 0.62, blue: 0.77)

        // TODO (Medium): Replace with Color("AccentDeep") from asset catalog
        // with Light variant: #ED5C8D, Dark variant: #FF7BA5
        public static let accentDeep = Color(red: 0.93, green: 0.36, blue: 0.55)

        // TODO (Medium): Replace with Color("WarmBg") from asset catalog
        // with Light variant: #FFF7F0, Dark variant: #2A1F1A
        public static let warmBg = Color(red: 1.00, green: 0.97, blue: 0.94)

        public static let textPrimary = Color.primary
        public static let textMuted = Color.secondary
        public static let xpTrack = Color.secondary.opacity(0.15)
    }

    public enum Typography {
        public static let title   = Font.system(.title2, design: .rounded, weight: .bold)
        public static let body    = Font.system(.body, design: .rounded)
        public static let caption = Font.system(.caption, design: .rounded)
        public static let chat    = Font.system(.callout, design: .rounded)
    }
}
