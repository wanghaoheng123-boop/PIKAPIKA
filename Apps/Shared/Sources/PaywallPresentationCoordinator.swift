import SwiftUI
import PikaSubscription

/// Single entry point for Pro upsell sheets: entitlement refresh, cooldown gate, and dismissal.
@MainActor
enum PaywallPresentationCoordinator {
    struct ActivePresentation: Identifiable, Equatable {
        let source: String
        var id: String { source }
    }

    /// Returns an active presentation when the user is on the free tier and the gate allows showing a paywall.
    static func requestPresentation(
        source: String,
        cooldownSeconds: TimeInterval = 90,
        forceRefresh: Bool = false
    ) async -> ActivePresentation? {
        if forceRefresh {
            await SharedSubscriptionManager.forceRefresh()
        } else {
            await SharedSubscriptionManager.refreshIfNeeded()
        }
        guard SharedSubscriptionManager.instance.currentEntitlements == .free else { return nil }
        guard PaywallPresentationGate.beginPresentation(source: source, cooldownSeconds: cooldownSeconds) else {
            return nil
        }
        return ActivePresentation(source: source)
    }

    static func dismiss(_ presentation: ActivePresentation?) {
        guard let presentation else { return }
        PaywallPresentationGate.endPresentation(source: presentation.source)
    }

    static func clearBinding(_ presentation: inout ActivePresentation?) {
        dismiss(presentation)
        presentation = nil
    }
}

private struct PaywallOfferSheetModifier: ViewModifier {
    @Binding var presentation: PaywallPresentationCoordinator.ActivePresentation?
    let onDismiss: (() -> Void)?
    @ObservedObject private var subscriptionManager = SharedSubscriptionManager.instance

    func body(content: Content) -> some View {
        content.sheet(item: $presentation) { item in
            SubscriptionOfferSheet(subscriptionManager: subscriptionManager, source: item.source) {
                onDismiss?()
                PaywallPresentationCoordinator.clearBinding(&presentation)
            }
        }
    }
}

extension View {
    func paywallOfferSheet(
        presentation: Binding<PaywallPresentationCoordinator.ActivePresentation?>,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        modifier(PaywallOfferSheetModifier(presentation: presentation, onDismiss: onDismiss))
    }
}
