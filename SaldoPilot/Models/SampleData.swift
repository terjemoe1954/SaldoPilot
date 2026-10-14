//
//  SampleData.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import Foundation
import SwiftData

enum SampleData {
    private static let syntheticTitlePrefix = "Belastningstest #"

    static func transactions() -> [Transaction] {
        [
            Transaction(
                title: "Husleie",
                amount: 14500,
                type: .expense,
                dueDate: .now,
                category: .home,
                recurrence: .monthly,
                recurrenceIntervalMonths: 1
            ),
            Transaction(
                title: "Lønn",
                amount: 42000,
                type: .income,
                dueDate: .now,
                status: .received,
                category: .income,
                isCompleted: true
            ),
            Transaction(
                title: "Strømmetjeneste",
                amount: 129,
                type: .expense,
                dueDate: .now,
                category: .subscriptions,
                recurrence: .monthly,
                recurrenceIntervalMonths: 1
            )
        ]
    }

    @MainActor
    static func ensureSyntheticTransactions(count: Int, in modelContext: ModelContext) throws {
        guard count > 0 else { return }

        let existing = try modelContext.fetch(FetchDescriptor<Transaction>())
        let existingIndexes = Set(
            existing.compactMap { transaction -> Int? in
                guard transaction.title.hasPrefix(syntheticTitlePrefix) else { return nil }
                return Int(transaction.title.dropFirst(syntheticTitlePrefix.count))
            }
        )
        guard existingIndexes.count < count else { return }

        let calendar = Calendar(identifier: .gregorian)
        let baseDate = calendar.startOfDay(for: .now)
        let categories = CategoryKind.allCases

        for index in 1...count where !existingIndexes.contains(index) {
            let isIncome = index.isMultiple(of: 5)
            let isSettled = index.isMultiple(of: 3)
            let dueDate = calendar.date(
                byAdding: .day,
                value: (index % 730) - 365,
                to: baseDate
            ) ?? baseDate
            let type: TransactionType = isIncome ? .income : .expense
            let status: TransactionStatus = isSettled
                ? (isIncome ? .received : .paid)
                : .pending

            modelContext.insert(
                Transaction(
                    title: "\(syntheticTitlePrefix)\(index)",
                    amount: Decimal((index % 5_000) + 1),
                    type: type,
                    dueDate: dueDate,
                    paidDate: isSettled ? dueDate : nil,
                    status: status,
                    category: categories[index % categories.count],
                    notes: "Synthetic isolated load-test data",
                    isCompleted: isSettled
                )
            )
        }

        try modelContext.save()
    }
}
