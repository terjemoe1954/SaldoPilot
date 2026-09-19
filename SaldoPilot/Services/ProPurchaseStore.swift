//
//  ProPurchaseStore.swift
//  SaldoPilot
//
//  Created by Codex on 19/09/2026.
//

import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class ProPurchaseStore {
    static let proProductID = "com.terjemoe.SaldoPilot.pro"

    var product: Product?
    var isLoading = false
    var isProUnlocked = false {
        didSet {
            let status: AppProStatus = isProUnlocked ? .pro : .free
            UserDefaults.standard.set(status.rawValue, forKey: AppSettingsKey.proStatus)
        }
    }
    var message: String?

    @ObservationIgnored private var transactionUpdatesTask: Task<Void, Never>?

    init() {
        transactionUpdatesTask = listenForTransactions()
        Task {
            await refresh()
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        await loadProduct()
        await refreshEntitlements()
    }

    func purchasePro() async {
        if product == nil {
            await refresh()
        }

        guard let product else {
            message = "SaldoPilot Pro is not available yet."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verificationResult):
                let transaction = try checkVerified(verificationResult)
                await transaction.finish()
                await refreshEntitlements()
                message = isProUnlocked ? "SaldoPilot Pro is unlocked." : "Purchase completed, but Pro is not unlocked yet."
            case .pending:
                message = "Purchase is pending approval."
            case .userCancelled:
                message = nil
            @unknown default:
                message = "Purchase could not be completed."
            }
        } catch {
            message = "Purchase failed. Please try again."
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            message = isProUnlocked ? "SaldoPilot Pro is restored." : "No Pro purchase was found."
        } catch {
            message = "Restore failed. Please try again."
        }
    }

    private func loadProduct() async {
        do {
            product = try await Product.products(for: [Self.proProductID]).first
        } catch {
            product = nil
            message = "Could not load SaldoPilot Pro from the App Store."
        }
    }

    private func refreshEntitlements() async {
        var hasProEntitlement = false

        for await result in StoreKit.Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else {
                continue
            }

            if transaction.productID == Self.proProductID {
                hasProEntitlement = true
                break
            }
        }

        isProUnlocked = hasProEntitlement
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self else { return }
                guard let transaction = try? self.checkVerified(result) else {
                    continue
                }

                if transaction.productID == Self.proProductID {
                    await self.refreshEntitlements()
                }

                await transaction.finish()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            value
        case .unverified:
            throw StoreError.failedVerification
        }
    }
}

private enum StoreError: Error {
    case failedVerification
}
