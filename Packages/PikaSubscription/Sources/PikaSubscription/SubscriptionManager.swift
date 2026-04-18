import Foundation
import StoreKit

/// StoreKit 2 wrapper. Observe `entitlementsStream` to drive paywall UI.
@MainActor
public final class SubscriptionManager: ObservableObject {

    @Published public private(set) var products: [Product] = []
    @Published public private(set) var currentEntitlements: Entitlements = .free
    @Published public private(set) var activeProductID: ProductID?

    private var transactionListener: Task<Void, Never>?

    public init() {
        transactionListener = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
    }

    deinit { transactionListener?.cancel() }

    public func loadProducts() async {
        do {
            let ids = ProductID.allCases.map(\.rawValue)
            products = try await Product.products(for: ids)
        } catch {
            products = []
        }
    }

    public func refreshEntitlements() async {
        var granted: Entitlements = .free
        var active: ProductID?
        for await entry in Transaction.currentEntitlements {
            if case .verified(let tx) = entry,
               let pid = ProductID(rawValue: tx.productID) {
                granted.formUnion(pid.entitlements)
                active = pid
            }
        }
        currentEntitlements = granted
        activeProductID = active
    }

    public func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(.verified(let tx)):
            await tx.finish()
            await refreshEntitlements()
            return true
        case .success(.unverified):
            return false
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    public func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    private func handle(_ update: VerificationResult<Transaction>) async {
        if case .verified(let tx) = update {
            await tx.finish()
            await refreshEntitlements()
        }
    }
}
