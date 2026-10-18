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
    private static let screenshotMarker = "SaldoPilot skjermbildedata"

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

    @MainActor
    static func ensureScreenshotData(in modelContext: ModelContext, language: AppLanguage) throws {
        let existing = try modelContext.fetch(FetchDescriptor<Transaction>())
        guard !existing.contains(where: { $0.notes == screenshotMarker }) else { return }

        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: .now)?.start ?? calendar.startOfDay(for: .now)

        func date(_ day: Int) -> Date {
            calendar.date(byAdding: .day, value: day - 1, to: monthStart) ?? monthStart
        }

        func title(_ norwegian: String, _ english: String) -> String {
            language == .english ? english : norwegian
        }

        let transactions: [Transaction] = [
            Transaction(title: title("Lønn", "Salary"), amount: 42_000, type: .income, dueDate: date(25), status: .pending, category: .income, recurrence: .monthly, recurrenceIntervalMonths: 1, notes: screenshotMarker),
            Transaction(title: title("App-design", "App design"), amount: 8_500, type: .income, dueDate: date(12), paidDate: date(12), status: .received, category: .developer, notes: screenshotMarker, isCompleted: true),
            Transaction(title: title("Bidrag husleie og strøm", "Rent and electricity contribution"), amount: 7_500, type: .income, dueDate: date(15), paidDate: date(15), status: .received, category: .refund, recurrence: .monthly, recurrenceIntervalMonths: 1, notes: screenshotMarker, isCompleted: true),
            Transaction(title: title("Husleie", "Rent"), amount: 14_500, type: .expense, dueDate: date(1), paidDate: date(1), status: .paid, category: .home, recurrence: .monthly, recurrenceIntervalMonths: 1, notes: screenshotMarker, isCompleted: true),
            Transaction(title: title("Strøm", "Electricity"), amount: 1_249, type: .expense, dueDate: date(17), paidDate: date(17), status: .paid, category: .home, recurrence: .monthly, recurrenceIntervalMonths: 1, notes: screenshotMarker, isCompleted: true),
            Transaction(title: title("Ukeshandel", "Weekly groceries"), amount: 875, type: .expense, dueDate: date(16), paidDate: date(16), status: .paid, category: .groceries, notes: screenshotMarker, isCompleted: true),
            Transaction(title: title("Middag ute", "Dinner out"), amount: 685, type: .expense, dueDate: date(16), paidDate: date(16), status: .paid, category: .diningOut, notes: screenshotMarker, isCompleted: true),
            Transaction(title: title("Busskort", "Transit pass"), amount: 897, type: .expense, dueDate: date(20), category: .transport, recurrence: .monthly, recurrenceIntervalMonths: 1, notes: screenshotMarker),
            Transaction(title: title("Utviklerprogram", "Developer program"), amount: 1_290, type: .expense, dueDate: date(21), category: .developer, recurrence: .yearly, notes: screenshotMarker),
            Transaction(title: title("Mobil og internett", "Phone and internet"), amount: 799, type: .expense, dueDate: date(22), category: .communication, recurrence: .monthly, recurrenceIntervalMonths: 1, notes: screenshotMarker),
            Transaction(title: title("Jakke og sko", "Jacket and shoes"), amount: 1_290, type: .expense, dueDate: date(23), category: .clothing, notes: screenshotMarker),
            Transaction(title: title("Innboforsikring", "Home insurance"), amount: 699, type: .expense, dueDate: date(24), category: .insurance, recurrence: .monthly, recurrenceIntervalMonths: 1, notes: screenshotMarker),
            Transaction(title: title("Kino", "Cinema"), amount: 220, type: .expense, dueDate: date(15), paidDate: date(15), status: .paid, category: .entertainment, notes: screenshotMarker, isCompleted: true),
            Transaction(title: title("Brilleabonnement", "Eyewear subscription"), amount: 375, type: .expense, dueDate: date(13), paidDate: date(13), status: .paid, category: .health, recurrence: .monthly, recurrenceIntervalMonths: 1, notes: screenshotMarker, isCompleted: true),
            Transaction(title: title("Restskatt", "Tax balance"), amount: 1_600, type: .expense, dueDate: date(28), category: .deduction, notes: screenshotMarker),
            Transaction(title: title("Overføring til sparekonto", "Transfer to savings"), amount: 2_500, type: .expense, dueDate: date(28), category: .savings, recurrence: .monthly, recurrenceIntervalMonths: 1, notes: screenshotMarker)
        ]

        transactions.forEach(modelContext.insert)

        for monthOffset in (-5)...(-1) {
            guard let historicalMonth = calendar.date(byAdding: .month, value: monthOffset, to: monthStart),
                  let incomeDate = calendar.date(byAdding: .day, value: 24, to: historicalMonth),
                  let expenseDate = calendar.date(byAdding: .day, value: 14, to: historicalMonth) else {
                continue
            }

            let incomeAmount = Decimal(39_000 + ((monthOffset + 5) * 750))
            let expenseAmount = Decimal(21_500 + ((monthOffset + 5) * 620))
            modelContext.insert(
                Transaction(
                    title: title("Lønn", "Salary"),
                    amount: incomeAmount,
                    type: .income,
                    dueDate: incomeDate,
                    paidDate: incomeDate,
                    status: .received,
                    category: .income,
                    notes: screenshotMarker,
                    isCompleted: true
                )
            )
            modelContext.insert(
                Transaction(
                    title: title("Månedens utgifter", "Monthly expenses"),
                    amount: expenseAmount,
                    type: .expense,
                    dueDate: expenseDate,
                    paidDate: expenseDate,
                    status: .paid,
                    category: .home,
                    notes: screenshotMarker,
                    isCompleted: true
                )
            )
        }

        let budgetAmounts: [(CategoryKind, Decimal)] = [
            (.home, 17_000),
            (.groceries, 5_000),
            (.transport, 1_500),
            (.diningOut, 1_800),
            (.entertainment, 2_500),
            (.income, 42_000)
        ]
        for (category, amount) in budgetAmounts {
            modelContext.insert(Budget(category: category, monthStart: monthStart, amount: amount))
        }

        try modelContext.save()
    }
}
