//
//  StatisticsView.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import Charts
import SwiftData
import SwiftUI

struct StatisticsView: View {
    @Environment(\.locale) private var locale
    @Query(sort: \Transaction.dueDate) private var transactions: [Transaction]
    @Query(sort: \CategoryDefinition.name) private var categoryDefinitions: [CategoryDefinition]
    @State private var selectedCategoryMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now

    let onNewTransaction: () -> Void

    var body: some View {
        NavigationStack {
            if visibleTransactions.isEmpty {
                ScrollView {
                    StatisticsEmptyState(onNewTransaction: onNewTransaction)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .navigationTitle("Statistics")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        StatisticsSummaryGrid(summary: snapshot.currentMonthSummary)

                        MonthlyComparisonChart(months: snapshot.months)
                        CategoryBalanceChart(
                            categories: snapshot.categoryBalances,
                            months: snapshot.months,
                            selectedMonth: $selectedCategoryMonth
                        )
                        NetTrendChart(months: snapshot.months)
                        OutstandingAmountChart(months: snapshot.outstandingMonths)
                    }
                    .padding()
                }
                .navigationTitle("Statistics")
            }
        }
    }

    private var visibleTransactions: [Transaction] {
        transactions.filter {
            !$0.isArchived && $0.status != .cancelled
        }
    }

    private var ordinaryTransactions: [Transaction] {
        visibleTransactions.filter(\.isIncludedInOrdinaryCashFlow)
    }

    private var categoryTransactions: [Transaction] {
        visibleTransactions.filter(\.isIncludedInCategoryActivity)
    }

    private var snapshot: StatisticsSnapshot {
        StatisticsSnapshot(
            ordinaryTransactions: ordinaryTransactions,
            categoryTransactions: categoryTransactions,
            locale: locale,
            categoryDefinitions: categoryDefinitions,
            selectedCategoryMonth: selectedCategoryMonth
        )
    }

}

private struct StatisticsEmptyState: View {
    let onNewTransaction: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No statistics yet", systemImage: "chart.bar.xaxis")
        } description: {
            Text("Add income and expenses to see trends, category balances and monthly comparisons.")
        } actions: {
            Button(action: onNewTransaction) {
                Label("New transaction", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct StatisticsSnapshot {
    let currentMonthSummary: StatisticsSummary
    let months: [MonthStatistics]
    let categoryBalances: [CategoryStatistics]
    let outstandingMonths: [OutstandingMonthStatistics]

    init(
        ordinaryTransactions: [Transaction],
        categoryTransactions: [Transaction],
        locale: Locale,
        categoryDefinitions: [CategoryDefinition],
        selectedCategoryMonth: Date
    ) {
        let calendar = Calendar.current
        let now = Date.now
        let currentMonthInterval = calendar.dateInterval(of: .month, for: now) ?? DateInterval(start: now, duration: 0)
        let currentMonthTransactions = ordinaryTransactions.filter { currentMonthInterval.containsHalfOpen($0.dueDate) }
        let categoryMonthInterval = calendar.dateInterval(of: .month, for: selectedCategoryMonth)
            ?? DateInterval(start: selectedCategoryMonth, duration: 0)
        let categoryMonthTransactions = categoryTransactions.filter { categoryMonthInterval.containsHalfOpen($0.dueDate) }

        currentMonthSummary = StatisticsSummary(transactions: currentMonthTransactions)
        months = Self.makeMonthStatistics(transactions: ordinaryTransactions, calendar: calendar)
        categoryBalances = Self.makeCategoryBalanceStatistics(transactions: categoryMonthTransactions, locale: locale, definitions: categoryDefinitions)
        outstandingMonths = Self.makeOutstandingMonthStatistics(transactions: ordinaryTransactions, calendar: calendar)
    }

    private static func makeMonthStatistics(transactions: [Transaction], calendar: Calendar) -> [MonthStatistics] {
        let monthStarts = rollingMonthStarts(count: 12, calendar: calendar)

        return monthStarts.map { monthStart in
            let interval = calendar.dateInterval(of: .month, for: monthStart) ?? DateInterval(start: monthStart, duration: 0)
            let monthTransactions = transactions.filter { interval.containsHalfOpen($0.dueDate) }
            return MonthStatistics(monthStart: monthStart, transactions: monthTransactions)
        }
    }

    private static func makeCategoryBalanceStatistics(transactions: [Transaction], locale: Locale, definitions: [CategoryDefinition]) -> [CategoryStatistics] {
        let groupedTransactions = Dictionary(grouping: transactions, by: \.categoryID)

        return groupedTransactions.map { categoryID, transactions in
            let category = CategoryOption.resolve(id: categoryID, definitions: definitions, locale: locale)
            let income = transactions.filter { $0.type == .income }.totalAmount
            let expenses = transactions.filter { $0.type == .expense }.totalAmount

            return CategoryStatistics(
                id: category.id,
                name: category.name,
                icon: category.systemImage,
                tint: category.tint,
                income: income,
                expenses: expenses,
                transactions: transactions.sortedByDueDate
            )
        }
        .sorted { abs($0.amount.doubleValue) > abs($1.amount.doubleValue) }
    }

    private static func makeOutstandingMonthStatistics(transactions: [Transaction], calendar: Calendar) -> [OutstandingMonthStatistics] {
        let outstandingTransactions = transactions.filter { transaction in
            transaction.type == .income &&
            !transaction.isCompleted &&
            transaction.status == .pending
        }
        let monthStarts = rollingMonthStarts(count: 12, calendar: calendar)

        return monthStarts.compactMap { monthStart in
            let interval = calendar.dateInterval(of: .month, for: monthStart) ?? DateInterval(start: monthStart, duration: 0)
            let monthTransactions = outstandingTransactions.filter { interval.containsHalfOpen($0.dueDate) }
            guard !monthTransactions.isEmpty else { return nil }
            return OutstandingMonthStatistics(monthStart: monthStart, transactions: monthTransactions)
        }
    }

    private static func rollingMonthStarts(count: Int, calendar: Calendar) -> [Date] {
        let currentMonthStart = calendar.dateInterval(of: .month, for: .now)?.start ?? .now
        return (0..<count).compactMap { offset in
            calendar.date(byAdding: .month, value: offset - (count - 1), to: currentMonthStart)
        }
    }
}

private struct StatisticsSummary {
    let income: Decimal
    let expenses: Decimal
    let outstandingReceivable: Decimal

    init(transactions: [Transaction]) {
        income = transactions.filter { $0.type == .income }.totalAmount
        expenses = transactions.filter { $0.type == .expense }.totalAmount
        outstandingReceivable = transactions.filter { transaction in
            transaction.type == .income && !transaction.isCompleted && transaction.status == .pending
        }.totalAmount
    }

    var net: Decimal {
        income - expenses
    }
}

private struct MonthStatistics: Identifiable {
    let monthStart: Date
    let transactions: [Transaction]

    var id: Date { monthStart }
    var income: Decimal { transactions.filter { $0.type == .income }.totalAmount }
    var expenses: Decimal { transactions.filter { $0.type == .expense }.totalAmount }
    var net: Decimal { income - expenses }
    func title(locale: Locale) -> String {
        monthStart.formatted(.dateTime.month(.abbreviated).year().locale(locale))
    }
}

private struct CategoryStatistics: Identifiable {
    let id: String
    let name: String
    let icon: String
    let tint: Color
    let income: Decimal
    let expenses: Decimal
    let transactions: [Transaction]

    var amount: Decimal {
        income - expenses
    }
}

private struct OutstandingMonthStatistics: Identifiable {
    let monthStart: Date
    let transactions: [Transaction]

    var id: Date { monthStart }
    var amount: Decimal { transactions.totalAmount }
    func title(locale: Locale) -> String {
        monthStart.formatted(.dateTime.month(.abbreviated).year().locale(locale))
    }
}

private struct StatisticsSummaryGrid: View {
    let summary: StatisticsSummary

    var body: some View {
        VStack(spacing: 12) {
            StatisticsNetHero(value: summary.net)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                StatisticsMetricCard(title: "Income", value: summary.income, systemImage: "arrow.down.circle", tint: .green)
                StatisticsMetricCard(title: "Expenses", value: summary.expenses, systemImage: "arrow.up.circle", tint: .red)
                StatisticsMetricCard(title: "Receivable", value: summary.outstandingReceivable, systemImage: "tray.and.arrow.down", tint: .blue)
            }
        }
    }
}

private struct StatisticsNetHero: View {
    let value: Decimal

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Net", systemImage: "equal.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))

                Text(value.formattedCurrency)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .contentTransition(.numericText())
            }

            Spacer(minLength: 8)

            Image(systemName: value >= .zero ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
                .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .accessibilityHidden(true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 124, alignment: .leading)
        .background {
            LinearGradient(
                colors: value >= .zero
                    ? [Color(red: 0, green: 0.29, blue: 0.60), Color(red: 0.21, green: 0.13, blue: 0.44)]
                    : [Color(red: 0.51, green: 0.22, blue: 0), Color(red: 0.54, green: 0.11, blue: 0.11)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: (value >= .zero ? Color.blue : Color.red).opacity(0.16), radius: 10, y: 5)
        .accessibilityElement(children: .combine)
    }
}

private struct StatisticsMetricCard: View {
    let title: LocalizedStringKey
    let value: Decimal
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value.formattedCurrency)
                .font(.title3.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.10), lineWidth: 1)
        }
    }
}

private struct MonthlyComparisonChart: View {
    @Environment(\.locale) private var locale

    let months: [MonthStatistics]

    var body: some View {
        StatisticsChartSection(title: "Income vs. expenses per month") {
            Chart {
                ForEach(months) { month in
                    BarMark(
                        x: .value("Month", month.monthStart, unit: .month),
                        y: .value("Amount", month.income.doubleValue)
                    )
                    .foregroundStyle(by: .value("Type", incomeLegendTitle))

                    BarMark(
                        x: .value("Month", month.monthStart, unit: .month),
                        y: .value("Amount", month.expenses.doubleValue)
                    )
                    .foregroundStyle(by: .value("Type", expenseLegendTitle))
                }
            }
            .chartYAxisLabel("Amount")
            .frame(height: 220)

            StatisticsMonthLinkList(months: months, subtitle: "Net", value: { $0.net })
        }
    }

    private func localized(_ value: String.LocalizationValue) -> String {
        String(localized: value, bundle: .main, locale: locale)
    }

    private var incomeLegendTitle: String {
        locale.usesNorwegianLanguage ? "Inntekter" : localized("Income")
    }

    private var expenseLegendTitle: String {
        locale.usesNorwegianLanguage ? "Utgifter" : localized("Expenses")
    }
}

private struct CategoryBalanceChart: View {
    let categories: [CategoryStatistics]
    let months: [MonthStatistics]
    @Binding var selectedMonth: Date

    var body: some View {
        StatisticsChartSection(title: "Category balance") {
            Picker("Month", selection: $selectedMonth) {
                ForEach(months) { month in
                    Text(month.monthStart, format: .dateTime.month(.wide).year())
                        .tag(month.monthStart)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            if categories.isEmpty {
                StatisticsEmptyChartState(text: "No category activity in the selected month.")
            } else {
                Chart(categories) { category in
                    BarMark(
                        x: .value("Net", category.amount.doubleValue),
                        y: .value("Category", category.name)
                    )
                    .foregroundStyle(category.amount >= .zero ? Color.green : Color.red)
                }
                .chartXAxisLabel("Net")
                .frame(height: max(220, CGFloat(categories.count) * 34))

                VStack(spacing: 8) {
                    ForEach(categories) { category in
                        NavigationLink {
                            StatisticsTransactionListView(
                                title: category.name,
                                transactions: category.transactions
                            )
                        } label: {
                            StatisticsCategoryRow(category: category)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct NetTrendChart: View {
    let months: [MonthStatistics]

    var body: some View {
        StatisticsChartSection(title: "Net development") {
            Chart(months) { month in
                LineMark(
                    x: .value("Month", month.monthStart, unit: .month),
                    y: .value("Net", month.net.doubleValue)
                )
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Month", month.monthStart, unit: .month),
                    y: .value("Net", month.net.doubleValue)
                )
            }
            .chartYAxisLabel("Net")
            .frame(height: 220)

            StatisticsMonthLinkList(months: months, subtitle: "Net", value: { $0.net })
        }
    }
}

private struct OutstandingAmountChart: View {
    @Environment(\.locale) private var locale

    let months: [OutstandingMonthStatistics]

    var body: some View {
        StatisticsChartSection(title: "Receivable amount") {
            if months.isEmpty {
                StatisticsEmptyChartState(text: "No receivable transactions.")
            } else {
                Chart(months) { month in
                    BarMark(
                        x: .value("Month", month.monthStart, unit: .month),
                        y: .value("Amount", month.amount.doubleValue)
                    )
                    .foregroundStyle(.blue)
                }
                .chartYAxisLabel("Amount")
                .frame(height: 220)

                VStack(spacing: 8) {
                    ForEach(months) { month in
                        NavigationLink {
                            StatisticsTransactionListView(
                                title: month.title(locale: locale),
                                transactions: month.transactions.sortedByDueDate
                            )
                        } label: {
                            StatisticsValueRow(
                                title: month.title(locale: locale),
                                subtitle: "Receivable",
                                value: month.amount,
                                systemImage: "clock.badge.exclamationmark"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct StatisticsChartSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary, lineWidth: 1)
        }
    }
}

private struct StatisticsMonthLinkList: View {
    @Environment(\.locale) private var locale

    let months: [MonthStatistics]
    let subtitle: LocalizedStringKey
    let value: (MonthStatistics) -> Decimal

    var body: some View {
        VStack(spacing: 8) {
            ForEach(months) { month in
                NavigationLink {
                    StatisticsTransactionListView(
                        title: month.title(locale: locale),
                        transactions: month.transactions.sortedByDueDate
                    )
                } label: {
                    StatisticsValueRow(
                        title: month.title(locale: locale),
                        subtitle: subtitle,
                        value: value(month),
                        systemImage: "calendar"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct StatisticsCategoryRow: View {
    let category: CategoryStatistics

    var body: some View {
        StatisticsValueRow(
            title: category.name,
            subtitle: "Net · \(category.transactions.count) transactions",
            value: category.amount,
            systemImage: category.icon
        )
    }
}

private struct StatisticsValueRow: View {
    let title: String
    let subtitle: LocalizedStringKey
    let value: Decimal
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(value.formattedCurrency)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}

private struct StatisticsEmptyChartState: View {
    let text: LocalizedStringKey

    var body: some View {
        ContentUnavailableView(text, systemImage: "chart.bar.doc.horizontal")
            .frame(height: 180)
    }
}

private struct StatisticsTransactionListView: View {
    let title: String
    let transactions: [Transaction]

    var body: some View {
        List(transactions, id: \.id) { transaction in
            StatisticsTransactionRow(transaction: transaction)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StatisticsTransactionRow: View {
    @Environment(\.locale) private var locale
    @Query(sort: \CategoryDefinition.name) private var categoryDefinitions: [CategoryDefinition]
    let transaction: Transaction

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: transaction.type == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.title3)
                .foregroundStyle(transaction.type == .income ? .green : .red)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 5) {
                Text(transaction.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(transaction.dueDate, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(CategoryOption.resolve(id: transaction.categoryID, definitions: categoryDefinitions, locale: locale).name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(transaction.amount.formattedCurrency)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(transaction.type == .income ? .green : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
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

private extension Decimal {
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}

private extension Locale {
    var usesNorwegianLanguage: Bool {
        guard let languageCode = language.languageCode?.identifier.lowercased() else { return false }
        return languageCode == "nb" || languageCode == "no" || languageCode == "nn"
    }
}

#Preview {
    StatisticsView(onNewTransaction: {})
}
