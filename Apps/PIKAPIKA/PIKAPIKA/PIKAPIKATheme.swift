import SwiftUI

/// Visual language: warm, playful “digital companion” (inspired by classic QQ pet care — soft, rounded, alive).
/// Target: people who want emotional stickiness + light gamification, not a clinical productivity tool.
enum PIKAPIKATheme {

    // MARK: - Brand (coral → orchid — friendly, spirited)

    static let accent = Color(red: 0.98, green: 0.42, blue: 0.45)
    static let accentSecondary = Color(red: 0.62, green: 0.38, blue: 0.95)
    static let warmth = Color(red: 1.0, green: 0.72, blue: 0.38)

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.45, green: 0.28, blue: 0.72),
                accent,
                warmth.opacity(0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var homeBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(.systemGroupedBackground),
                Color(red: 0.97, green: 0.94, blue: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(.secondarySystemGroupedBackground),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let cornerLarge: CGFloat = 22
    static let cornerMedium: CGFloat = 16
    static let cornerChip: CGFloat = 20

    static let shadowSoft = Color.black.opacity(0.08)
}

enum PikaMetrics {
    static let screenHorizontal: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
}
