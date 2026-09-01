import StoreKit
import SwiftUI

@MainActor
final class EntitlementStore: ObservableObject {
    static let monthlyID = "de.kamilunavo.rapportai.pro.monthly"
    static let annualID = "de.kamilunavo.rapportai.pro.annual"
    static let productIDs = [monthlyID, annualID]

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro = false
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit { updatesTask?.cancel() }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: Self.productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Die Pro-Angebote konnten gerade nicht geladen werden."
        }
    }

    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .pending:
                errorMessage = "Der Kauf wartet noch auf Bestätigung. Pro wird erst danach freigeschaltet."
            case .userCancelled:
                break
            @unknown default:
                errorMessage = "Der Kauf wurde nicht abgeschlossen."
            }
        } catch {
            errorMessage = "Der Kauf konnte nicht abgeschlossen werden: \(error.localizedDescription)"
        }
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = "Käufe konnten nicht wiederhergestellt werden: \(error.localizedDescription)"
        }
    }

    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verified(result) else { continue }
            if Self.productIDs.contains(transaction.productID), transaction.revocationDate == nil {
                active = true
            }
        }
        isPro = active
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self, let transaction = try? self.verified(result) else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): value
        case .unverified: throw StoreError.failedVerification
        }
    }

    enum StoreError: Error { case failedVerification }
}

