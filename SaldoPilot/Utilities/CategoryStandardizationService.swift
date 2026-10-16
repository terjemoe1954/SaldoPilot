import Foundation
import SwiftData

@MainActor
enum CategoryStandardizationService {
    static func standardize(in modelContext: ModelContext) throws {
        let transactions = try modelContext.fetch(FetchDescriptor<Transaction>())
        var changed = false

        for transaction in transactions {
            guard let category = standardizedCategory(for: transaction) else { continue }
            transaction.category = category
            changed = true
        }

        if changed {
            try modelContext.save()
        }
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

        if title.contains("restskatt") || title.contains("back tax") {
            return transaction.category == .deduction ? nil : .deduction
        }

        if title.contains("brilleabonnement") || title.contains("glasses subscription") {
            return transaction.category == .health ? nil : .health
        }

        if developerTerms.contains(where: title.contains) {
            return transaction.category == .developer ? nil : .developer
        }

        return nil
    }

    private static let diningOutTerms = [
        "burger king", "mcdonald", "hamburger", "fast food", "ferdigmat kjøpt ute",
        "takeaway", "take away", "gatekjøkken"
    ]

    private static let communicationTerms = [
        "mobil", "mobile", "telefon", "phone", "internett", "internet", "tv pakke", "tvpakke"
    ]

    private static let developerTerms = [
        "chatgpt", "openai", "app store connect", "xcode"
    ]
}

private extension String {
    var normalizedForCategoryRules: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
    }
}
