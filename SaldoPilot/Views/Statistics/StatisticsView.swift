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
    @Query(sort: \Transaction.dueDate) private var transactions: [Transaction]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    StatisticsSummaryGrid(summary: snapshot.currentMonthSummary)

                    MonthlyComparisonChart(months: snapshot.months)
                    ExpenseCategoryChart(categories: snapshot.expenseCategories)
                    NetTrendChart(months: snapshot.months)
                    OutstandingAmountChart(months: snapshot.outstandingMonths)
                }
                .padding()
            }
            .navigationTitle("Statistics")
        }
    }

    private var activeTransactions: [Transaction] {
        transactions.filter { !$0.isArchived && $0.status != .cancelled }
    }

    private var snapshot: StatisticsSnapshot {
        StatisticsSnapshot(transactions: activeTransactions)
    }
}

private struct StatisticsSnapshot {
    let currentMonthSummary: StatisticsSummary
    let months: [MonthStatistics]
    let expenseCategories: [CategoryStatistics]
    let outstandingMonths: [OutstandingMonthStatistics]

    init(transactions: [Transaction]) {
        let calendar = Calendar.current
        let now = Date.now
        let currentMonthInterval = calendar.dateInterval(of: .month, for: now) ?? DateInterval(start: now, duration: 0)
        let currentMonthTransactions = transactions.filter { currentMonthInterval.contains($0.dueDate) }

        currentMonthSummary = StatisticsSummary(transactions: currentMonthTransactions)
        months = Self.makeMonthStatistics(transactions: transactions, calendar: calendar)
        expenseCategories = Self.makeExpenseCategoryStatistics(transactions: currentMonthTransactions)
        outstandingMonths = Self.makeOutstandingMonthStatistics(transactions: transactions, calendar: calendar)
    }

    private static func makeMonthStatistics(transactions: [Transaction], calendar: Calendar) -> [MonthStatistics] {
        let monthStarts = rollingMonthStarts(count: 12, calendar: calendar)

        return monthStarts.map { monthStart in
            let interval = calendar.dateInterval(of: .month, for: monthStart) ?? DateInterval(start: monthStart, duration: 0)
            let monthTransactions = transactions.filter { interval.contains($0.dueDate) }
            return MonthStatistics(monthStart: monthStart, transactions: monthTransactions)
        }
    }

    private static func makeExpenseCategoryStatistics(transactions: [Transaction]) -> [CategoryStatistics] {
        let expenseTransactions = transactions.filter { $0.type == .expense }
        let groupedTransactions = Dictionary(grouping: expenseTransactions, by: \.category)

        return groupedTransactions.map { category, transactions in
            CategoryStatistics(
                id: category.rawValue,
                name: String(localized: category.title),
                icon: category.systemImage,
                amount: transactions.totalAmount,
                transactions: transactions.sortedByDueDate
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    private static func makeOutstandingMonthStatistics(transactions: [Transaction], calendar: Calendar) -> [OutstandingMonthStatistics] {
        let outstandingTransactions = transactions.filter { transaction in
            !transaction.isCompleted && (transaction.effectiveStatus == .pending || transaction.effectiveStatus == .overdue)
        }
        let monthStarts = rollingMonthStarts(count: 12, calendar: calendar)

        return monthStarts.compactMap { monthStart in
            let interval = calendar.dateInterval(of: .month, for: monthStart) ?? DateInterval(start: monthStart, duration: 0)
            let monthTransactions = outstandingTransactions.filter { interval.contains($0.dueDate) }
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
    var title: String { monthStart.formatted(.dateTime.month(.abbreviated).year()) }
}

private struct CategoryStatistics: Identifiable {
    let id: String
    let name: String
    let icon: String
    let amount: Decimal
    let transactions: [Transaction]
}

private struct OutstandingMonthStatistics: Identifiable {
    let monthStart: Date
    let transactions: [Transaction]

    var id: Date { monthStart }
    var amount: Decimal { transactions.totalAmount }
    var title: String { monthStart.formatted(.dateTime.month(.abbreviated).year()) }
}

private struct StatisticsSummaryGrid: View {
    let summary: StatisticsSummary

    var body: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            StatisticsMetricCard(title: "Income", value: summary.income, systemImage: "arrow.down.circle", tint: .green)
            StatisticsMetricCard(title: "Expenses", value: summary.expenses, systemImage: "arrow.up.circle", tint: .red)
            StatisticsMetricCard(title: "Net", value: summary.net, systemImage: "equal.circle", tint: summary.net >= 0 ? .green : .red)
            StatisticsMetricCard(title: "Receivable", value: summary.outstandingReceivable, systemImage: "tray.and.arrow.down", tint: .blue)
        }
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
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary, lineWidth: 1)
        }
    }
}

private struct MonthlyComparisonChart: View {
    let months: [MonthStatistics]

    var body: some View {
        StatisticsChartSection(title: "Income vs. expenses per month") {
            Chart {
                ForEach(months) { month in
                    BarMark(
                        x: .value("Month", month.monthStart, unit: .month),
                        y: .value("Amount", month.income.doubleValue)
                    )
                    .foregroundStyle(by: .value("Type", String(localized: "Income")))

                    BarMark(
                        x: .value("Month", month.monthStart, unit: .month),
                        y: .value("Amount", month.expenses.doubleValue)
                    )
                    .foregroundStyle(by: .value("Type", String(localized: "Expenses")))
                }
            }
            .chartYAxisLabel("Amount")
            .frame(height: 220)

            StatisticsMonthLinkList(months: months, value: { $0.income + $0.expenses })
        }
    }
}

private struct ExpenseCategoryChart: View {
    let categories: [CategoryStatistics]

    var body: some View {
        StatisticsChartSection(title: "Expenses per category") {
            if categories.isEmpty {
                StatisticsEmptyChartState(text: "No expenses this month.")
            } else {
                Chart(categories) { category in
                    SectorMark(
                        angle: .value("Amount", category.amount.doubleValue),
                        innerRadius: .ratio(0.58),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Category", category.name))
                }
                .frame(height: 220)

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

            StatisticsMonthLinkList(months: months, value: { $0.net })
        }
    }
}

private struct OutstandingAmountChart: View {
    let months: [OutstandingMonthStatistics]

    var body: some View {
        StatisticsChartSection(title: "Outstanding amount") {
            if months.isEmpty {
                StatisticsEmptyChartState(text: "No outstanding transactions.")
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
                                title: month.title,
                                transactions: month.transactions.sortedByDueDate
                            )
                        } label: {
                            StatisticsValueRow(
                                title: month.title,
                                subtitle: "Outstanding",
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
    let months: [MonthStatistics]
    let value: (MonthStatistics) -> Decimal

    var body: some View {
        VStack(spacing: 8) {
            ForEach(months) { month in
                NavigationLink {
                    StatisticsTransactionListView(
                        title: month.title,
                        transactions: month.transactions.sortedByDueDate
                    )
                } label: {
                    StatisticsValueRow(
                        title: month.title,
                        subtitle: "Transactions",
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
            subtitle: "Expenses",
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

                Text(transaction.category.title)
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

#Preview {
    StatisticsView()
}
