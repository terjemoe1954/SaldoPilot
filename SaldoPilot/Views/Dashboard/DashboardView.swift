//
//  DashboardView.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import SwiftData
import SwiftUI

struct DashboardView: View {
    @Query(sort: \Transaction.dueDate) private var transactions: [Transaction]
    @AppStorage(AppSettingsKey.defaultPeriod) private var selectedPeriodRawValue = AppDefaultPeriod.thisMonth.rawValue
    @AppStorage(AppSettingsKey.language) private var languageRawValue = AppLanguage.system.rawValue
    @AppStorage(AppSettingsKey.showNameOnDashboard) private var showNameOnDashboard = false
    @AppStorage(AppSettingsKey.displayName) private var displayName = ""
    @State private var customStartDate = Calendar.current.currentMonthStart
    @State private var customEndDate = Calendar.current.currentMonthEnd
    @State private var isShowingAIQuery = false

    let onNewIncome: () -> Void
    let onNewExpense: () -> Void
    let onRegisterPayment: () -> Void
    let onShowTransactions: (TransactionListFilter) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if showNameOnDashboard && !displayName.trimmedForDisplay.isEmpty {
                        DashboardGreetingView(name: displayName.trimmedForDisplay)
                    }

                    DashboardPeriodSection(
                        selectedPeriod: selectedPeriodBinding,
                        customStartDate: $customStartDate,
                        customEndDate: $customEndDate
                    )

                    DashboardSummarySection(
                        summary: summary,
                        onShowOverdue: { onShowTransactions(.overdue) },
                        onShowNextDue: { onShowTransactions(.nextDue) }
                    )

                    AIInsightSection(insights: aiInsights) {
                        isShowingAIQuery = true
                    }

                    DashboardAttentionSection(
                        items: attentionItems,
                        onShowTransactions: { onShowTransactions(.all) },
                        onSelectItem: { item in
                            onShowTransactions(item.listFilter)
                        }
                    )

                    DashboardQuickActionsSection(
                        onNewIncome: onNewIncome,
                        onNewExpense: onNewExpense,
                        onRegisterPayment: onRegisterPayment
                    )
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Overview")
            .sheet(isPresented: $isShowingAIQuery) {
                AIQueryView(transactions: activeTransactions)
            }
        }
    }

    private var selectedPeriod: DashboardPeriod {
        DashboardPeriod(rawValue: selectedPeriodRawValue) ?? .thisMonth
    }

    private var selectedPeriodBinding: Binding<DashboardPeriod> {
        Binding {
            selectedPeriod
        } set: { newValue in
            selectedPeriodRawValue = newValue.rawValue
        }
    }

    private var periodInterval: DateInterval {
        selectedPeriod.interval(
            calendar: .current,
            customStartDate: customStartDate,
            customEndDate: customEndDate
        )
    }

    private var activeTransactions: [Transaction] {
        transactions.filter { !$0.isArchived && $0.status != .cancelled }
    }

    private var periodTransactions: [Transaction] {
        activeTransactions.filter { periodInterval.contains($0.dueDate) }
    }

    private var summary: DashboardSummary {
        let income = periodTransactions
            .filter { $0.type == .income }
            .reduce(Decimal.zero) { $0 + $1.amount }

        let expenses = periodTransactions
            .filter { $0.type == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount }

        let outstanding = periodTransactions
            .filter { $0.type == .income && !$0.isCompleted && $0.status == .pending }
            .reduce(Decimal.zero) { $0 + $1.amount }

        let overdueCount = activeTransactions.filter { $0.effectiveStatus == .overdue }.count
        let nextDueDate = activeTransactions
            .filter { $0.type == .expense && $0.status == .pending && !$0.isCompleted && $0.dueDate >= Calendar.current.startOfDay(for: .now) }
            .map(\.dueDate)
            .min()

        return DashboardSummary(
            income: income,
            expenses: expenses,
            net: income - expenses,
            outstanding: outstanding,
            overdueCount: overdueCount,
            nextDueDate: nextDueDate
        )
    }

    private var aiInsights: [AIInsight] {
        AIInsightEngine.insights(transactions: activeTransactions, locale: selectedLanguage.locale)
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .system
    }

    private var attentionItems: [DashboardAttentionItem] {
        let today = Calendar.current.startOfDay(for: .now)
        let soon = Calendar.current.date(byAdding: .day, value: 7, to: today) ?? today

        let overdue = activeTransactions.filter { $0.effectiveStatus == .overdue }
        let dueSoon = activeTransactions.filter {
            $0.type == .expense && $0.status == .pending && !$0.isCompleted && $0.dueDate >= today && $0.dueDate <= soon
        }
        let pendingIncome = activeTransactions.filter {
            $0.type == .income &&
            $0.status == .pending &&
            !$0.isCompleted &&
            periodInterval.contains($0.dueDate)
        }

        var items: [DashboardAttentionItem] = []

        if !overdue.isEmpty {
            items.append(
                DashboardAttentionItem(
                    id: "overdue",
                    title: "Overdue transactions",
                    value: "\(overdue.count)",
                    systemImage: "exclamationmark.triangle",
                    tint: .red
                )
            )
        }

        if !dueSoon.isEmpty {
            items.append(
                DashboardAttentionItem(
                    id: "dueSoon",
                    title: "Due soon",
                    value: "\(dueSoon.count)",
                    systemImage: "calendar.badge.clock",
                    tint: .orange
                )
            )
        }

        if !pendingIncome.isEmpty {
            items.append(
                DashboardAttentionItem(
                    id: "pendingIncome",
                    title: "Pending income",
                    value: pendingIncome.totalAmount.formattedCurrency,
                    systemImage: "arrow.down.circle",
                    tint: .green
                )
            )
        }

        return items
    }
}

private enum DashboardPeriod: String, CaseIterable, Identifiable {
    case thisMonth
    case previousMonth
    case thisYear
    case custom

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .thisMonth:
            "This month"
        case .previousMonth:
            "Previous month"
        case .thisYear:
            "This year"
        case .custom:
            "Custom"
        }
    }

    func interval(calendar: Calendar, customStartDate: Date, customEndDate: Date) -> DateInterval {
        let now = Date.now

        switch self {
        case .thisMonth:
            return calendar.dateInterval(of: .month, for: now) ?? DateInterval(start: now, duration: 0)
        case .previousMonth:
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return calendar.dateInterval(of: .month, for: previousMonth) ?? DateInterval(start: previousMonth, duration: 0)
        case .thisYear:
            return calendar.dateInterval(of: .year, for: now) ?? DateInterval(start: now, duration: 0)
        case .custom:
            let start = calendar.startOfDay(for: min(customStartDate, customEndDate))
            let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: max(customStartDate, customEndDate))) ?? start
            return DateInterval(start: start, end: end)
        }
    }
}

private struct DashboardSummary {
    let income: Decimal
    let expenses: Decimal
    let net: Decimal
    let outstanding: Decimal
    let overdueCount: Int
    let nextDueDate: Date?
}

private struct DashboardAttentionItem: Identifiable {
    let id: String
    let title: LocalizedStringKey
    let value: String
    let systemImage: String
    let tint: Color

    var listFilter: TransactionListFilter {
        switch id {
        case "overdue":
            .overdue
        case "dueSoon":
            .upcoming
        case "pendingIncome":
            .receivable
        default:
            .all
        }
    }
}

private struct DashboardGreetingView: View {
    let name: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hello, \(name)")
                .font(.title2.weight(.semibold))
                .lineLimit(2)

            Text("Here is your current balance picture.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}

private struct DashboardPeriodSection: View {
    @Binding var selectedPeriod: DashboardPeriod
    @Binding var customStartDate: Date
    @Binding var customEndDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Period")
                .font(.headline)

            Picker("Period", selection: $selectedPeriod) {
                ForEach(DashboardPeriod.allCases) { period in
                    Text(period.title).tag(period)
                }
            }
            .pickerStyle(.segmented)

            if selectedPeriod == .custom {
                VStack(spacing: 8) {
                    DatePicker("From", selection: $customStartDate, displayedComponents: .date)
                    DatePicker("To", selection: $customEndDate, displayedComponents: .date)
                }
                .padding(12)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

private struct DashboardSummarySection: View {
    let summary: DashboardSummary
    let onShowOverdue: () -> Void
    let onShowNextDue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                DashboardSummaryTile(title: "Income", amount: summary.income, systemImage: "arrow.down.circle", tint: .green)
                DashboardSummaryTile(title: "Expenses", amount: summary.expenses, systemImage: "arrow.up.circle", tint: .red)
                DashboardSummaryTile(title: "Net", amount: summary.net, systemImage: "equal.circle", tint: .blue)
                DashboardSummaryTile(title: "Receivable", amount: summary.outstanding, systemImage: "clock.badge.checkmark", tint: .orange)
            }

            HStack(spacing: 12) {
                Button(action: onShowOverdue) {
                    DashboardCountTile(title: "Overdue", value: summary.overdueCount, systemImage: "exclamationmark.triangle", tint: .red)
                }
                .buttonStyle(.plain)
                .disabled(summary.overdueCount == 0)

                Button(action: onShowNextDue) {
                    DashboardNextDueTile(date: summary.nextDueDate)
                }
                .buttonStyle(.plain)
                .disabled(summary.nextDueDate == nil)
            }
        }
    }
}

private struct DashboardSummaryTile: View {
    let title: LocalizedStringKey
    let amount: Decimal
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .foregroundStyle(tint)

            Text(amount.formattedCurrency)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}

private struct DashboardCountTile: View {
    let title: LocalizedStringKey
    let value: Int
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .foregroundStyle(tint)

            Text(value, format: .number)
                .font(.title3.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}

private struct DashboardNextDueTile: View {
    let date: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Next due", systemImage: "calendar")
                .font(.subheadline)
                .foregroundStyle(.blue)

            if let date {
                Text(date, format: .dateTime.day().month().year())
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            } else {
                Text("None")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}

private struct AIInsightSection: View {
    let insights: [AIInsight]
    let onAsk: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.blue)
                Text("AI summary")
                    .font(.headline)

                Spacer()

                Button(action: onAsk) {
                    Label("Ask", systemImage: "text.bubble")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            VStack(spacing: 10) {
                ForEach(insights) { insight in
                    AIInsightRow(insight: insight)
                }
            }
        }
    }
}

private struct AIInsightRow: View {
    let insight: AIInsight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.systemImage)
                .font(.title3)
                .foregroundStyle(insight.tint)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(insight.title)
                    .font(.subheadline.weight(.semibold))

                Text(insight.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}

private struct DashboardAttentionSection: View {
    let items: [DashboardAttentionItem]
    let onShowTransactions: () -> Void
    let onSelectItem: (DashboardAttentionItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Needs attention")
                    .font(.headline)

                Spacer()

                Button("See all", action: onShowTransactions)
                    .buttonStyle(.borderless)
            }

            if items.isEmpty {
                ContentUnavailableView(
                    "No transactions need attention",
                    systemImage: "checkmark.circle",
                    description: Text("When something is due or waiting for action, it will appear here.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                VStack(spacing: 10) {
                    ForEach(items) { item in
                        Button {
                            onSelectItem(item)
                        } label: {
                            DashboardAttentionRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct DashboardAttentionRow: View {
    let item: DashboardAttentionItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.systemImage)
                .font(.title3)
                .foregroundStyle(item.tint)
                .frame(width: 28)

            Text(item.title)
                .font(.body)

            Spacer()

            Text(item.value)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}

private struct DashboardQuickActionsSection: View {
    let onNewIncome: () -> Void
    let onNewExpense: () -> Void
    let onRegisterPayment: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)

            VStack(spacing: 10) {
                Button(action: onNewIncome) {
                    Label("New income", systemImage: "arrow.down.circle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(action: onNewExpense) {
                    Label("New expense", systemImage: "arrow.up.circle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(action: onRegisterPayment) {
                    Label("Register payment", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.bordered)
        }
    }
}

private extension String {
    var trimmedForDisplay: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension Calendar {
    var currentMonthStart: Date {
        dateInterval(of: .month, for: .now)?.start ?? startOfDay(for: .now)
    }

    var currentMonthEnd: Date {
        guard let monthInterval = dateInterval(of: .month, for: .now) else {
            return startOfDay(for: .now)
        }

        return date(byAdding: .day, value: -1, to: monthInterval.end) ?? monthInterval.start
    }
}

private extension Array where Element == Transaction {
    var totalAmount: Decimal {
        reduce(Decimal.zero) { $0 + $1.amount }
    }
}

#Preview {
    DashboardView(
        onNewIncome: {},
        onNewExpense: {},
        onRegisterPayment: {},
        onShowTransactions: { _ in }
    )
}
