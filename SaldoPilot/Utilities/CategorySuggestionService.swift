import Foundation

enum CategorySuggestionService {
    static func suggestion(
        for title: String,
        using transactions: [Transaction],
        excluding transactionID: UUID? = nil
    ) -> CategoryKind? {
        let normalizedTitle = title.normalizedCategorySuggestionKey
        guard normalizedTitle.count >= 3 else { return nil }

        if let reimbursementCategory = reimbursementCategory(
            for: title,
            using: transactions,
            excluding: transactionID
        ) {
            return reimbursementCategory
        }

        let historicalMatches = transactions.filter { transaction in
            transaction.id != transactionID
                && transaction.category != .other
                && transaction.title.normalizedCategorySuggestionKey == normalizedTitle
        }

        if !historicalMatches.isEmpty {
            let grouped = Dictionary(grouping: historicalMatches, by: \.category)
            return grouped.max { first, second in
                if first.value.count == second.value.count {
                    return (first.value.map(\.updatedAt).max() ?? .distantPast)
                        < (second.value.map(\.updatedAt).max() ?? .distantPast)
                }
                return first.value.count < second.value.count
            }?.key
        }

        return CategoryKind.allCases.first { category in
            category != .other && category.matches(transactionTitle: title)
        }
    }

    static func reimbursementCategory(
        for title: String,
        using transactions: [Transaction],
        excluding transactionID: UUID? = nil
    ) -> CategoryKind? {
        let normalizedTitle = title.normalizedCategorySuggestionKey
        let markers = ["tilbakebetaling av utlegg", "refusjon for", "refund for", "reimbursement for"]
        guard let marker = markers.first(where: normalizedTitle.contains) else { return nil }

        let reference = normalizedTitle
            .replacingOccurrences(of: marker, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard reference.count >= 3 else { return nil }

        let matchingCategories = Set(
            transactions.compactMap { transaction -> CategoryKind? in
                guard transaction.id != transactionID,
                      transaction.type == .expense,
                      transaction.category != .other,
                      transaction.category != .refund
                else { return nil }

                let historicalTitle = transaction.title.normalizedCategorySuggestionKey
                guard historicalTitle.contains(reference) || reference.contains(historicalTitle) else {
                    return nil
                }
                return transaction.category
            }
        )

        return matchingCategories.count == 1 ? matchingCategories.first : nil
    }
}

private extension String {
    var normalizedCategorySuggestionKey: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
