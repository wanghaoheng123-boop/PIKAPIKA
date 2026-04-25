import SwiftUI
import StoreKit
import PikaSubscription
import SharedUI

struct SubscriptionOfferSheet: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    let source: String
    let onContinueFree: () -> Void

    @State private var purchasingProductID: String?
    @State private var purchaseErrorText: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: PikaTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: PikaTheme.Spacing.sm) {
                    Text("Unlock PIKAPIKA Pro")
                        .font(PikaTheme.Typography.title)
                    Text("Grow deeper companion personalities, keep memories synced, and create unlimited pets.")
                        .font(PikaTheme.Typography.body)
                        .foregroundStyle(PikaTheme.Palette.textMuted)
                }

                VStack(spacing: PikaTheme.Spacing.sm) {
                    ForEach(subscriptionManager.products, id: \.id) { product in
                        Button {
                            Task { await purchase(product) }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(product.displayName)
                                        .font(PikaTheme.Typography.body.weight(.semibold))
                                    Text(product.description)
                                        .font(PikaTheme.Typography.caption)
                                        .foregroundStyle(PikaTheme.Palette.textMuted)
                                        .lineLimit(2)
                                }
                                Spacer()
                                Text(product.displayPrice)
                                    .font(PikaTheme.Typography.body.weight(.semibold))
                            }
                            .padding(PikaTheme.Spacing.md)
                            .background(PikaTheme.Palette.card)
                            .clipShape(RoundedRectangle(cornerRadius: PikaTheme.Radius.card))
                        }
                        .disabled(purchasingProductID != nil || subscriptionManager.activeProductID?.rawValue == product.id)
                        .buttonStyle(.plain)
                    }
                }

                Button("Restore purchases") {
                    Task {
                        SubscriptionAnalytics.track(.restoreTapped, source: source)
                        await subscriptionManager.restorePurchases()
                        await SharedSubscriptionManager.forceRefresh()
                        if let managerError = SharedSubscriptionManager.latestErrorMessage() {
                            purchaseErrorText = managerError
                        }
                    }
                }
                .disabled(purchasingProductID != nil)

                if let purchaseErrorText {
                    Text(purchaseErrorText)
                        .font(PikaTheme.Typography.caption)
                        .foregroundStyle(.red)
                }

                Button("Continue free") {
                    onContinueFree()
                }
                .foregroundStyle(PikaTheme.Palette.textMuted)
            }
            .padding(PikaTheme.Spacing.lg)
            .navigationTitle("Upgrade")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") {
                        onContinueFree()
                    }
                }
            }
        }
        .task {
            SubscriptionAnalytics.track(.paywallShown, source: source)
            await SharedSubscriptionManager.refreshIfNeeded(minInterval: 0)
        }
    }

    @MainActor
    private func purchase(_ product: Product) async {
        purchasingProductID = product.id
        purchaseErrorText = nil
        defer { purchasingProductID = nil }
        SubscriptionAnalytics.track(.purchaseStarted, source: source)
        do {
            let purchased = try await subscriptionManager.purchase(product)
            if purchased {
                await SharedSubscriptionManager.forceRefresh()
                SubscriptionAnalytics.track(.purchaseSucceeded, source: source)
                onContinueFree()
            } else {
                SubscriptionAnalytics.track(.purchaseNotCompleted, source: source)
                purchaseErrorText = "Purchase was not completed. You can try again anytime."
            }
        } catch {
            SubscriptionAnalytics.track(.purchaseNotCompleted, source: source)
            purchaseErrorText = SharedSubscriptionManager.latestErrorMessage() ?? "Purchase failed. Please check your connection and try again."
        }
    }
}
