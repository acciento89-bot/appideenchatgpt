import Combine
import Foundation
import StoreKit

@MainActor
final class EntitlementStore: ObservableObject {
    static let shared = EntitlementStore()
    static let lifetimeProductID = "de.kamilunavo.trace.pro.lifetime"
    static let freeActiveCaseLimit = 3

    @Published private(set) var isPro = false
    @Published private(set) var lifetimeProduct: Product?
    @Published private(set) var isLoading = false
    @Published var lastErrorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                guard case .verified(let transaction) = update else { continue }
                await self.processVerifiedTransaction(transaction)
            }
        }

        Task { await load() }
    }

    deinit {
        updatesTask?.cancel()
    }

    var displayPrice: String {
        lifetimeProduct?.displayPrice ?? L10n.string("pro.price_loading")
    }

    func canCreateCase(currentCount: Int) -> Bool {
        isPro || currentCount < Self.freeActiveCaseLimit
    }

    func load() async {
        lastErrorMessage = nil
        isLoading = true
        defer { isLoading = false }

        // Existing customers must recover Pro from verified entitlements even when
        // product metadata is temporarily unavailable from the App Store.
        await refreshEntitlements()
        await finishUnfinishedLifetimeTransactions()

        do {
            lifetimeProduct = try await Product.products(for: [Self.lifetimeProductID]).first
            if lifetimeProduct == nil && !isPro {
                lastErrorMessage = L10n.string("pro.error_unavailable")
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func purchaseLifetime() async {
        lastErrorMessage = nil

        if lifetimeProduct == nil {
            await load()
        }

        guard let lifetimeProduct else {
            if lastErrorMessage == nil {
                lastErrorMessage = L10n.string("pro.error_unavailable")
            }
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            switch try await lifetimeProduct.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification,
                      transaction.productID == Self.lifetimeProductID else {
                    lastErrorMessage = L10n.string("pro.error_verification")
                    return
                }
                await processVerifiedTransaction(transaction)

            case .pending:
                lastErrorMessage = L10n.string("pro.error_pending")

            case .userCancelled:
                break

            @unknown default:
                break
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        lastErrorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            // Explicit restore is the only place where AppStore.sync() is used.
            try await AppStore.sync()
            await refreshEntitlements()
            await finishUnfinishedLifetimeTransactions()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var hasLifetime = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productID == Self.lifetimeProductID else { continue }
            if transaction.revocationDate == nil {
                hasLifetime = true
            }
        }

        isPro = hasLifetime
    }

    private func processVerifiedTransaction(_ transaction: Transaction) async {
        guard transaction.productID == Self.lifetimeProductID else { return }

        isPro = transaction.revocationDate == nil
        await transaction.finish()
        await refreshEntitlements()
    }

    private func finishUnfinishedLifetimeTransactions() async {
        var processed = false

        for await result in Transaction.unfinished {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productID == Self.lifetimeProductID else { continue }

            processed = true
            if transaction.revocationDate == nil {
                isPro = true
            }
            await transaction.finish()
        }

        if processed {
            await refreshEntitlements()
        }
    }
}
