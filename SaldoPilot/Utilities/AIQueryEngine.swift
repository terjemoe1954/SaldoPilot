//
//  AIQueryEngine.swift
//  SaldoPilot
//
//  Created by Terje Moe on 13/09/2026.
//

import Foundation

struct AIQueryResult: Equatable {
    let title: String
    let answer: String
    let transactions: [Transaction]
}

enum AIQueryEngine {
    static func answer(question: String, transactions: [Transaction], calendar: Calendar = .current, locale: Locale = .autoupdatingCurrent) -> AIQueryResult {
        let activeTransactions = transactions.filter { !$0.isArchived && $0.status != .cancelled }
        let normalizedQuestion = question.normalizedAIQuery

        if normalizedQuestion.containsAny(of: ["next week", "neste uke", "due", "forfaller", "ครบกำหนด"]) {
            return dueNextWeekResult(transactions: activeTransactions, calendar: calendar, locale: locale)
        }

        if normalizedQuestion.containsAny(of: ["increased most", "økt mest", "okt mest", "เพิ่มขึ้นมากที่สุด"]) {
            return biggestIncreaseResult(transactions: activeTransactions, calendar: calendar, locale: locale)
        }

        if normalizedQuestion.containsAny(of: ["save", "spare", "ประหยัด"]) {
            return savingsResult(transactions: activeTransactions, calendar: calendar, locale: locale)
        }

        if let category = CategoryKind.allCases.first(where: { normalizedQuestion.contains($0.rawValue) || normalizedQuestion.contains(localizedResource($0.title, locale: locale).normalizedAIQuery) }), normalizedQuestion.containsAny(of: ["how much", "hvor mye", "เท่าไร", "เท่าไหร่"]) {
            return categorySpendingResult(category: category, question: normalizedQuestion, transactions: activeTransactions, calendar: calendar, locale: locale)
        }

        if normalizedQuestion.containsAny(of: ["over", "above", "over", "มากกว่า"]), let amount = normalizedQuestion.firstDecimalNumber {
            return amountSearchResult(amount: amount, question: normalizedQuestion, transactions: activeTransactions, calendar: calendar, locale: locale)
        }

        return overviewResult(transactions: activeTransactions, calendar: calendar, locale: locale)
    }

    private static func dueNextWeekResult(transactions: [Transaction], calendar: Calendar, locale: Locale) -> AIQueryResult {
        let today = calendar.startOfDay(for: .now)
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        let matches = transactions.filter { transaction in
            transaction.type == .expense &&
            transaction.status == .pending &&
            !transaction.isCompleted &&
            transaction.dueDate >= today &&
            transaction.dueDate <= nextWeek
        }.sortedByDueDate

        return AIQueryResult(
            title: localizedValue("Due next week", locale: locale),
            answer: localizedValue("You have \(matches.count) transactions totaling \(matches.totalAmount.formattedCurrency) due in the next 7 days.", locale: locale),
            transactions: matches
        )
    }

    private static func categorySpendingResult(category: CategoryKind, question: String, transactions: [Transaction], calendar: Calendar, locale: Locale) -> AIQueryResult {
        let interval = question.containsAny(of: ["year", "år", "ar", "ปี"]) ?
            calendar.dateInterval(of: .year, for: .now) :
            calendar.dateInterval(of: .month, for: .now)

        let matches = transactions.filter { transaction in
            transaction.type == .expense &&
            transaction.category == category &&
            interval?.contains(transaction.dueDate) == true
        }.sortedByDueDate

        let categoryName = localizedResource(category.title, locale: locale)
        return AIQueryResult(
            title: categoryName,
            answer: localizedValue("You spent \(matches.totalAmount.formattedCurrency) on \(categoryName).", locale: locale),
            transactions: matches
        )
    }

    private static func biggestIncreaseResult(transactions: [Transaction], calendar: Calendar, locale: Locale) -> AIQueryResult {
        guard
            let currentMonth = calendar.dateInterval(of: .month, for: .now),
            let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: currentMonth.start),
            let previousMonth = calendar.dateInterval(of: .month, for: previousMonthDate)
        else {
            return overviewResult(transactions: transactions, calendar: calendar, locale: locale)
        }

        let changes = CategoryKind.allCases.compactMap { category -> (category: CategoryKind, difference: Decimal, matches: [Transaction])? in
            let current = transactions.filter { $0.type == .expense && $0.category == category && currentMonth.contains($0.dueDate) }
            let previous = transactions.filter { $0.type == .expense && $0.category == category && previousMonth.contains($0.dueDate) }
            let difference = current.totalAmount - previous.totalAmount
            guard difference > 0 else { return nil }
            return (category, difference, current.sortedByDueDate)
        }

        guard let largest = changes.max(by: { $0.difference < $1.difference }) else {
            return AIQueryResult(
                title: localizedValue("Spending change", locale: locale),
                answer: localizedValue("No expense category has increased compared with last month.", locale: locale),
                transactions: []
            )
        }

        let categoryName = localizedResource(largest.category.title, locale: locale)
        return AIQueryResult(
            title: localizedValue("Spending change", locale: locale),
            answer: localizedValue("\(categoryName) increased the most, up \(largest.difference.formattedCurrency) from last month.", locale: locale),
            transactions: largest.matches
        )
    }

    private static func savingsResult(transactions: [Transaction], calendar: Calendar, locale: Locale) -> AIQueryResult {
        guard let currentMonth = calendar.dateInterval(of: .month, for: .now) else {
            return overviewResult(transactions: transactions, calendar: calendar, locale: locale)
        }

        let categoryTotals = CategoryKind.allCases.compactMap { category -> (category: CategoryKind, amount: Decimal, matches: [Transaction])? in
            let matches = transactions.filter { $0.type == .expense && $0.category == category && currentMonth.contains($0.dueDate) }
            guard !matches.isEmpty else { return nil }
            return (category, matches.totalAmount, matches.sortedByDueDate)
        }

        guard let largest = categoryTotals.max(by: { $0.amount < $1.amount }) else {
            return AIQueryResult(
                title: localizedValue("Savings idea", locale: locale),
                answer: localizedValue("Add categories to expenses and SaldoPilot can point out where to review spending.", locale: locale),
                transactions: []
            )
        }

        let categoryName = localizedResource(largest.category.title, locale: locale)
        return AIQueryResult(
            title: localizedValue("Savings idea", locale: locale),
            answer: localizedValue("Review \(categoryName). It is your largest expense category this month at \(largest.amount.formattedCurrency).", locale: locale),
            transactions: largest.matches
        )
    }

    private static func amountSearchResult(amount: Decimal, question: String, transactions: [Transaction], calendar: Calendar, locale: Locale) -> AIQueryResult {
        let requestedYear = question.firstYear
        let category = CategoryKind.allCases.first { question.contains($0.rawValue) || question.contains(localizedResource($0.title, locale: locale).normalizedAIQuery) }
        let titleWords = question.significantQueryWords(excluding: CategoryKind.allCases.map { localizedResource($0.title, locale: locale) })

        let matches = transactions.filter { transaction in
            guard transaction.amount > amount else { return false }
            if let requestedYear, calendar.component(.year, from: transaction.dueDate) != requestedYear { return false }
            if let category, transaction.category != category { return false }
            if !titleWords.isEmpty {
                let title = transaction.title.normalizedAIQuery
                return titleWords.contains { title.contains($0) }
            }
            return true
        }.sortedByDueDate

        return AIQueryResult(
            title: localizedValue("Search result", locale: locale),
            answer: localizedValue("Found \(matches.count) transactions over \(amount.formattedCurrency).", locale: locale),
            transactions: matches
        )
    }

    private static func overviewResult(transactions: [Transaction], calendar: Calendar, locale: Locale) -> AIQueryResult {
        guard let currentMonth = calendar.dateInterval(of: .month, for: .now) else {
            return AIQueryResult(title: localizedValue("AI answer", locale: locale), answer: localizedValue("I could not read the current period.", locale: locale), transactions: [])
        }

        let currentTransactions = transactions.filter { currentMonth.contains($0.dueDate) }
        let income = currentTransactions.filter { $0.type == .income }.totalAmount
        let expenses = currentTransactions.filter { $0.type == .expense }.totalAmount
        let net = income - expenses

        return AIQueryResult(
            title: localizedValue("AI answer", locale: locale),
            answer: localizedValue("This month has \(income.formattedCurrency) in income, \(expenses.formattedCurrency) in expenses, and \(net.formattedCurrency) net.", locale: locale),
            transactions: currentTransactions.sortedByDueDate
        )
    }

    private static func localizedValue(_ value: String.LocalizationValue, locale: Locale) -> String {
        String(localized: value, bundle: .main, locale: locale)
    }

    private static func localizedResource(_ value: LocalizedStringResource, locale: Locale) -> String {
        String(localized: value)
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
    var normalizedAIQuery: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }

    var firstDecimalNumber: Decimal? {
        let pattern = #"\d+(?:[\s.,]\d+)*"#
        guard let range = range(of: pattern, options: .regularExpression) else { return nil }
        let rawValue = String(self[range])
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Decimal(string: rawValue, locale: Locale(identifier: "en_US_POSIX"))
    }

    var firstYear: Int? {
        let pattern = #"\b20\d{2}\b"#
        guard let range = range(of: pattern, options: .regularExpression) else { return nil }
        return Int(self[range])
    }

    func containsAny(of terms: [String]) -> Bool {
        terms.contains { contains($0.normalizedAIQuery) }
    }

    func significantQueryWords(excluding categoryNames: [String]) -> [String] {
        let excludedWords = Set(
            (["show", "vis", "all", "alle", "over", "above", "under", "in", "i", "on", "på", "pa", "kr", "nok", "year", "år", "ar"] + categoryNames.flatMap { $0.normalizedAIQuery.split(separator: " ").map(String.init) })
        )

        return split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { $0.count > 2 && !excludedWords.contains($0) && Int($0) == nil }
    }
}
