import Foundation
import SwiftData

enum CategoryStandardizationService {
    @MainActor
    static func standardize(in modelContext: ModelContext) throws {
        let transactions = try modelContext.fetch(FetchDescriptor<Transaction>())
        guard standardize(transactions: transactions) else { return }
        try modelContext.save()
    }

    @discardableResult
    static func standardize(transactions: [Transaction]) -> Bool {
        var changed = false

        for transaction in transactions {
            let category = transaction.category == .other
                ? CategorySuggestionService.reimbursementCategory(
                    for: transaction.title,
                    using: transactions,
                    excluding: transaction.id
                ) ?? standardizedCategory(for: transaction)
                : standardizedCategory(for: transaction)
            guard let category else { continue }
            transaction.category = category
            changed = true
        }

        return changed
    }

    static func standardizedCategory(for transaction: Transaction) -> CategoryKind? {
        let title = transaction.title.normalizedForCategoryRules

        if transaction.category == .other, diningOutTerms.contains(where: title.contains) {
            return .diningOut
        }

        if transaction.category == .subscriptions,
           communicationTerms.contains(where: title.contains) {
            return .communication
        }

        if transaction.category == .other,
           (title.contains("restskatt") || title.contains("back tax")) {
            return .deduction
        }

        if transaction.category == .subscriptions,
           (title.contains("brilleabonnement") || title.contains("glasses subscription")) {
            return .health
        }

        if [.other, .subscriptions].contains(transaction.category),
           developerTerms.contains(where: title.contains) {
            return .developer
        }

        if transaction.category == .other,
           refundTerms.contains(where: title.contains) {
            return .refund
        }

        return nil
    }

    private static let diningOutTerms = [
        "burger king", "mcdonald", "hamburger", "fast food", "ferdigmat kjøpt ute",
        "takeaway", "take away", "gatekjøkken", "restaurant", "kafe", "cafe"
    ]

    private static let communicationTerms = [
        "mobil", "mobile", "telefon", "phone", "internett", "internet", "tv pakke", "tvpakke"
    ]

    private static let developerTerms = [
        "chatgpt", "openai", "app store connect", "xcode"
    ]

    private static let refundTerms = [
        "refusjon", "refund", "cashback"
    ]
}

private extension String {
    var normalizedForCategoryRules: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
    }
}
