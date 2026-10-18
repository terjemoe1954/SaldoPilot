//
//  DashboardView.swift
// SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.locale) private var locale
    @Query(sort: \Transaction.dueDate) private var transactions: [Transaction]
    @AppStorage(AppSettingsKey.defaultPeriod) private var selectedPeriodRawValue = AppDefaultPeriod.thisMonth.rawValue
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

                    if activeTransactions.isEmpty {
                        DashboardGettingStartedCard(
                            onNewIncome: onNewIncome,
                            onNewExpense: onNewExpense
                        )
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

                    DashboardQuickActionsSection(
                        onNewIncome: onNewIncome,
                        onNewExpense: onNewExpense,
                        onRegisterPayment: onRegisterPayment
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

                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Overview")
            .sheet(isPresented: $isShowingAIQuery) {
                AIQueryView(transactions: activeTransactions.filter(\.isIncludedInOrdinaryCashFlow))
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
        activeTransactions.filter {
            $0.isIncludedInOrdinaryCashFlow && periodInterval.containsHalfOpen($0.dueDate)
        }
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
        AIInsightEngine.insights(
            transactions: activeTransactions.filter(\.isIncludedInOrdinaryCashFlow),
            locale: locale
        )
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
            periodInterval.containsHalfOpen($0.dueDate)
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

private struct DashboardGettingStartedCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let onNewIncome: () -> Void
    let onNewExpense: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 14) {
                    DashboardGettingStartedIcon()
                    DashboardGettingStartedText()
                }
            } else {
                HStack(alignment: .top, spacing: 14) {
                    DashboardGettingStartedIcon()
                    DashboardGettingStartedText()
                }
            }

            ViewThatFits {
                HStack(spacing: 10) {
                    actionButtons
                }

                VStack(spacing: 10) {
                    actionButtons
                }
            }
        }
        .padding(18)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.blue.opacity(0.14), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        Button(action: onNewIncome) {
            Label("Add income", systemImage: "plus.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)

        Button(action: onNewExpense) {
            Label("Add expense", systemImage: "minus.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }
}

private struct DashboardGettingStartedIcon: View {
    var body: some View {
        Image(systemName: "flag.checkered")
            .font(.title2.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityHidden(true)
    }
}

private struct DashboardGettingStartedText: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Start with your first entry")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text("Add income and expenses to make your overview useful right away.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
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
        .padding(.horizontal, 2)
        .accessibilityElement(children: .combine)
    }
}

private struct DashboardPeriodSection: View {
    @Binding var selectedPeriod: DashboardPeriod
    @Binding var customStartDate: Date
    @Binding var customEndDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Label("Period", systemImage: "calendar")
                    .font(.headline)

                Spacer()

                Picker("Period", selection: $selectedPeriod) {
                    ForEach(DashboardPeriod.allCases) { period in
                        Text(period.title).tag(period)
                    }
                }
                .pickerStyle(.menu)
            }

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
            DashboardNetHero(amount: summary.net)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                DashboardSummaryTile(title: "Income", amount: summary.income, systemImage: "arrow.down.circle", tint: .green)
                DashboardSummaryTile(title: "Expenses", amount: summary.expenses, systemImage: "arrow.up.circle", tint: .red)
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

private struct DashboardNetHero: View {
    let amount: Decimal

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Net", systemImage: "equal.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))

                Text(amount.formattedCurrency)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .contentTransition(.numericText())
            }

            Spacer(minLength: 8)

            Image(systemName: amount >= .zero ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
                .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .accessibilityHidden(true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
        .background {
            LinearGradient(
                colors: amount >= .zero
                    ? [Color(red: 0, green: 0.29, blue: 0.60), Color(red: 0.21, green: 0.13, blue: 0.44)]
                    : [Color(red: 0.51, green: 0.22, blue: 0), Color(red: 0.54, green: 0.11, blue: 0.11)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: (amount >= .zero ? Color.blue : Color.red).opacity(0.18), radius: 12, y: 6)
        .accessibilityElement(children: .combine)
    }
}

private struct DashboardSummaryTile: View {
    let title: LocalizedStringKey
    let amount: Decimal
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 42, height: 42)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(amount.formattedCurrency)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .contentTransition(.numericText())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 1)
        }
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

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 10)], spacing: 10) {
                DashboardActionButton(
                    title: "New income",
                    systemImage: "arrow.down.circle.fill",
                    tint: .green,
                    action: onNewIncome
                )
                DashboardActionButton(
                    title: "New expense",
                    systemImage: "arrow.up.circle.fill",
                    tint: .red,
                    action: onNewExpense
                )
                DashboardActionButton(
                    title: "Register payment",
                    systemImage: "checkmark.circle.fill",
                    tint: .blue,
                    action: onRegisterPayment
                )
            }
        }
    }
}

private struct DashboardActionButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title3)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .padding(.horizontal, 14)
            .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
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
