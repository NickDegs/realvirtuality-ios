import Foundation
import StoreKit

/// Native In-App Purchase (StoreKit 2). Digital upgrades MUST use IAP, not an
/// external web checkout (App Store Guideline 3.1.1). Unlocking is driven by
/// StoreKit's cryptographically verified on-device entitlements.
@MainActor
final class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var entitledTier: SubscriptionTier = .free
    @Published var isLoading = false
    @Published var purchasing: String?      // productID currently being bought
    @Published var error: String?

    /// Product IDs — must be created identically in App Store Connect.
    static let productIDs: [String] = [
        "app.downify.pro",            // Non-Consumable  (Pro, reklamsız)
        "app.downify.full.monthly",   // Auto-Renewable  (Full aylık)
        "app.downify.full.yearly",    // Auto-Renewable  (Full yıllık)
        "app.downify.full.lifetime",  // Non-Consumable  (Full ömür boyu)
    ]

    static func tier(for productID: String) -> SubscriptionTier {
        productID == "app.downify.pro" ? .adFree : .full
    }

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactions()
        Task { await loadProducts(); await refreshEntitlements() }
    }

    deinit { updatesTask?.cancel() }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await Product.products(for: Self.productIDs)
            products = fetched.sorted { $0.price < $1.price }
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Returns true on a successful, verified purchase.
    func purchase(_ product: Product) async -> Bool {
        purchasing = product.id
        defer { purchasing = nil }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await refreshEntitlements()
                // Best-effort: keep server tier in sync (failure doesn't block unlock).
                try? await APIService.shared.recordIAP(productId: transaction.productID,
                                                        transactionId: String(transaction.id))
                await transaction.finish()
                return true
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    /// Apple requires a visible "Restore Purchases" action (Guideline 3.1.1).
    func restore() async {
        isLoading = true
        defer { isLoading = false }
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var best: SubscriptionTier = .free
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.revocationDate != nil { continue }
            let t = Self.tier(for: transaction.productID)
            if t.rank > best.rank { best = t }
        }
        entitledTier = best
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                if let transaction = try? await self.checkVerified(result) {
                    await self.refreshEntitlements()
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    enum StoreError: Error { case failedVerification }
}
