//
//  AIInsightEngine.swift
//  SaldoPilot
//
//  Created by Terje Moe on 13/09/2026.
//

import Foundation
import SwiftUI

struct AIInsight: Identifiable, Equatable {
    let id: String
    let title: LocalizedStringResource
    let message: String
    let systemImage: String
    let tint: Color
}

enum AIInsightEngine {
    static func insights(transactions: [Transaction], categories: [Category], calendar: Calendar = .current) -> [AIInsight] {
        let activeTransactions = transactions.filter { !$0.isArchived && $0.status != .cancelled }
        guard !activeTransactions.isEmpty else {
            return [
                AIInsight(
                    id: "empty",
                    title: "AI summary",
                    message: String(localized: "Add a few transactions and SaldoPilot will summarize patterns here."),
                    systemImage: "sparkles",
                    tint: .blue
                )
            ]
        }

        var insights: [AIInsight] = []

        if let situationInsight = financialSituationInsight(transactions: activeTransactions, calendar: calendar) {
            insights.append(situationInsight)
        }

        if let spendingChangeInsight = spendingChangeInsight(transactions: activeTransactions, calendar: calendar) {
            insights.append(spendingChangeInsight)
        }

        if let dueSoonInsight = dueSoonInsight(transactions: activeTransactions, calendar: calendar) {
            insights.append(dueSoonInsight)
        }

        if let recurringInsight = recurringInsight(transactions: activeTransactions) {
            insights.append(recurringInsight)
        }

        if let unusualAmountInsight = unusualAmountInsight(transactions: activeTransactions) {
            insights.append(unusualAmountInsight)
        }

        if let categorySuggestionInsight = categorySuggestionInsight(transactions: activeTransactions, categories: categories) {
            insights.append(categorySuggestionInsight)
        }

        if insights.isEmpty, let summaryInsight = summaryInsight(transactions: activeTransactions, calendar: calendar) {
            insights.append(summaryInsight)
        }

        insights.append(
            AIInsight(
                id: "safety",
                title: "Advisory only",
                message: String(localized: "These insights are local suggestions. SaldoPilot does not act as a bank or financial advisor."),
                systemImage: "checkmark.shield",
                tint: .secondary
            )
        )

        return Array(insights.prefix(6))
    }

    private static func financialSituationInsight(transactions: [Transaction], calendar: Calendar) -> AIInsight? {
        let now = Date.now
        guard let currentMonth = calendar.dateInterval(of: .month, for: now) else { return nil }
        let currentTransactions = transactions.filter { currentMonth.contains($0.dueDate) }
        guard !currentTransactions.isEmpty else { return nil }

        let income = currentTransactions.filter { $0.type == .income }.totalAmount
        let expenses = currentTransactions.filter { $0.type == .expense }.totalAmount
        let net = income - expenses

        let message: String
        if net >= 0 {
            message = String(localized: "This month is positive by \(net.formattedCurrency) after registered income and expenses.")
        } else {
            message = String(localized: "This month is negative by \(abs(net).formattedCurrency) after registered income and expenses.")
        }

        return AIInsight(
            id: "situation",
            title: "Financial situation",
            message: message,
            systemImage: "text.magnifyingglass",
            tint: net >= 0 ? .green : .orange
        )
    }

    private static func spendingChangeInsight(transactions: [Transaction], calendar: Calendar) -> AIInsight? {
        let now = Date.now
        guard
            let currentMonth = calendar.dateInterval(of: .month, for: now),
            let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: currentMonth.start),
            let previousMonth = calendar.dateInterval(of: .month, for: previousMonthDate)
        else { return nil }

        let currentExpenses = transactions.filter { $0.type == .expense && currentMonth.contains($0.dueDate) }.totalAmount
        let previousExpenses = transactions.filter { $0.type == .expense && previousMonth.contains($0.dueDate) }.totalAmount
        guard currentExpenses > 0 || previousExpenses > 0 else { return nil }

        let difference = currentExpenses - previousExpenses
        guard abs(difference) >= 1 else { return nil }

        let message: String
        let tint: Color
        if difference > 0 {
            message = String(localized: "Expenses this month are \(difference.formattedCurrency) higher than last month.")
            tint = .orange
        } else {
            message = String(localized: "Expenses this month are \(abs(difference).formattedCurrency) lower than last month.")
            tint = .green
        }

        return AIInsight(
            id: "spendingChange",
            title: "Spending change",
            message: message,
            systemImage: "chart.line.uptrend.xyaxis",
            tint: tint
        )
    }

    private static func dueSoonInsight(transactions: [Transaction], calendar: Calendar) -> AIInsight? {
        let today = calendar.startOfDay(for: .now)
        guard let endDate = calendar.date(byAdding: .day, value: 7, to: today) else { return nil }
        let dueSoon = transactions.filter { transaction in
            transaction.status == .pending &&
            !transaction.isCompleted &&
            transaction.dueDate >= today &&
            transaction.dueDate <= endDate
        }
        guard !dueSoon.isEmpty else { return nil }

        return AIInsight(
            id: "dueSoon",
            title: "Upcoming payments",
            message: String(localized: "You have \(dueSoon.count) transactions totaling \(dueSoon.totalAmount.formattedCurrency) due in the next 7 days."),
            systemImage: "calendar.badge.clock",
            tint: .red
        )
    }

    private static func recurringInsight(transactions: [Transaction]) -> AIInsight? {
        let candidates = transactions.filter { !$0.isCompleted && $0.recurrence == .none }
        let grouped = Dictionary(grouping: candidates) { transaction in
            "\(transaction.title.normalizedInsightKey)-\(transaction.amount.description)-\(transaction.type.rawValue)"
        }

        guard let group = grouped.values
            .filter({ $0.count >= 2 })
            .sorted(by: { $0.count > $1.count })
            .first,
            let firstTransaction = group.sortedByDueDate.first
        else { return nil }

        return AIInsight(
            id: "recurring",
            title: "Possible recurring transaction",
            message: String(localized: "\(firstTransaction.title) appears more than once with the same amount. It may be recurring."),
            systemImage: "repeat",
            tint: .purple
        )
    }

    private static func unusualAmountInsight(transactions: [Transaction]) -> AIInsight? {
        let expenseTransactions = transactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenseTransactions) { transaction in
            transaction.category?.id.uuidString ?? "no-category"
        }

        for group in grouped.values where group.count >= 3 {
            let average = group.totalAmount / Decimal(group.count)
            guard average > 0 else { continue }

            if let unusual = group.max(by: { $0.amount < $1.amount }), unusual.amount >= average * 2 {
                return AIInsight(
                    id: "unusualAmount",
                    title: "Unusual amount",
                    message: String(localized: "\(unusual.title) is much higher than similar registered expenses."),
                    systemImage: "exclamationmark.magnifyingglass",
                    tint: .orange
                )
            }
        }

        return nil
    }

    private static func categorySuggestionInsight(transactions: [Transaction], categories: [Category]) -> AIInsight? {
        let uncategorized = transactions.filter { $0.category == nil }
        guard !uncategorized.isEmpty, !categories.isEmpty else { return nil }

        for transaction in uncategorized {
            let title = transaction.title.localizedCaseInsensitiveFolded
            if let category = categories.first(where: { title.contains($0.name.localizedCaseInsensitiveFolded) }) {
                return AIInsight(
                    id: "categorySuggestion",
                    title: "Suggested category",
                    message: String(localized: "\(transaction.title) may fit the \(category.name) category."),
                    systemImage: "tag",
                    tint: .blue
                )
            }
        }

        return nil
    }

    private static func summaryInsight(transactions: [Transaction], calendar: Calendar) -> AIInsight? {
        let today = calendar.startOfDay(for: .now)
        guard let weekStart = calendar.date(byAdding: .day, value: -7, to: today) else { return nil }
        let recentTransactions = transactions.filter { $0.dueDate >= weekStart && $0.dueDate <= today }
        guard !recentTransactions.isEmpty else { return nil }

        let income = recentTransactions.filter { $0.type == .income }.totalAmount
        let expenses = recentTransactions.filter { $0.type == .expense }.totalAmount

        return AIInsight(
            id: "weeklySummary",
            title: "Weekly summary",
            message: String(localized: "The last 7 days include \(income.formattedCurrency) in income and \(expenses.formattedCurrency) in expenses."),
            systemImage: "calendar",
            tint: .blue
        )
    }
}

private extension Array where Element == Transaction {
    var totalAmount: Decimal {
        reduce(Decimal.zero) { partialResult, transaction in
            partialResult + transaction.amount
        }
    }

    var sortedByDueDate: [Transaction] {
        sorted { first, second in
            first.dueDate < second.dueDate
        }
    }
}

private extension String {
    var normalizedInsightKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var localizedCaseInsensitiveFolded: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}
