//
//  BudgetsView.swift
//  SaldoPilot
//
//  Created by Codex on 24/09/2026.
//

import SwiftData
import SwiftUI

struct BudgetsView: View {
    @Environment(ProPurchaseStore.self) private var proPurchaseStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Query(sort: \Budget.monthStart) private var budgets: [Budget]
    @Query(sort: \Transaction.dueDate) private var transactions: [Transaction]

    @State private var budgetDraft: BudgetDraft?
    @State private var isShowingProInfo = false

    var body: some View {
        NavigationStack {
            Group {
                if canUseBudgets {
                    budgetContent
                } else {
                    proLockedContent
                }
            }
            .navigationTitle("Budgets")
            .toolbar {
                if canUseBudgets {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            openBudgetForm(category: .home)
                        } label: {
                            Label("Set budget", systemImage: "plus")
                        }
                    }
                }
            }
            .sheet(item: $budgetDraft) { draft in
                BudgetFormView(
                    category: draft.category,
                    amount: draft.amount,
                    onSave: saveBudget
                )
            }
            .sheet(isPresented: $isShowingProInfo) {
                NavigationStack {
                    ProInfoView()
                }
            }
            .task {
                await proPurchaseStore.refresh()
                carryForwardBudgetsIfNeeded()
            }
        }
    }

    private var canUseBudgets: Bool {
        #if DEBUG
        true
        #else
        proPurchaseStore.isProUnlocked
        #endif
    }

    private var budgetContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if currentMonthBudgets.isEmpty {
                    BudgetGettingStartedCard {
                        openBudgetForm(category: .home)
                    }
                }

                BudgetSummarySection(summary: budgetSummary)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Monthly category budgets")
                        .font(.headline)

                    ForEach(budgetRows) { row in
                        Button {
                            openBudgetForm(category: row.category)
                        } label: {
                            BudgetCategoryRowView(row: row)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var proLockedContent: some View {
        ContentUnavailableView {
            Label("Budgets are a Pro feature", systemImage: "star.circle")
        } description: {
            Text("Use SaldoPilot Pro to set monthly category budgets and see how much remains this month.")
        } actions: {
            Button {
                isShowingProInfo = true
            } label: {
                Label("Open SaldoPilot Pro", systemImage: "star.circle")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var currentMonthStart: Date {
        Calendar.current.dateInterval(of: .month, for: .now)?.start ?? Calendar.current.startOfDay(for: .now)
    }

    private var currentMonthInterval: DateInterval {
        Calendar.current.dateInterval(of: .month, for: .now) ?? DateInterval(start: currentMonthStart, duration: 0)
    }

    private var currentMonthBudgets: [Budget] {
        budgets.filter { Calendar.current.isDate($0.monthStart, equalTo: currentMonthStart, toGranularity: .month) }
    }

    private var currentMonthTransactions: [Transaction] {
        transactions.filter { transaction in
            !transaction.isArchived &&
            transaction.status != .cancelled &&
            transaction.isIncludedInCategoryActivity &&
            currentMonthInterval.containsHalfOpen(transaction.dueDate)
        }
    }

    private var budgetRows: [BudgetCategoryRow] {
        CategoryKind.sortedForDisplay(locale: locale).map { category in
            let budget = currentMonthBudgets.first { $0.category == category }
            let categoryTransactions = currentMonthTransactions.filter { $0.category == category }
            let income = categoryTransactions
                .filter { $0.type == .income }
                .totalAmount
            let expenses = categoryTransactions
                .filter { $0.type == .expense }
                .totalAmount
            return BudgetCategoryRow(
                category: category,
                categoryTitle: category.localizedTitle(locale: locale),
                systemImage: category.systemImage,
                tint: category.tint,
                budgetAmount: budget?.amount ?? .zero,
                incomeAmount: income,
                expenseAmount: expenses
            )
        }
    }

    private var budgetSummary: BudgetSummary {
        BudgetSummary(
            rows: budgetRows.filter { $0.category != .savings }
        )
    }

    private func openBudgetForm(category: CategoryKind) {
        budgetDraft = BudgetDraft(
            category: category,
            amount: currentMonthBudgets.first { $0.category == category }?.amount ?? .zero
        )
    }

    private func saveBudget(category: CategoryKind, amount: Decimal) {
        if let budget = currentMonthBudgets.first(where: { $0.category == category }) {
            budget.amount = amount
            budget.markUpdated()
        } else {
            modelContext.insert(
                Budget(
                    category: category,
                    monthStart: currentMonthStart,
                    amount: amount
                )
            )
        }

        try? modelContext.save()
    }

    @MainActor
    private func carryForwardBudgetsIfNeeded() {
        guard canUseBudgets else { return }

        let calendar = Calendar.current
        let earlierBudgets = budgets.filter { $0.monthStart < currentMonthStart }
        guard let sourceMonthStart = earlierBudgets.compactMap({ budget in
            calendar.dateInterval(of: .month, for: budget.monthStart)?.start
        }).max() else {
            return
        }

        let sourceBudgets = earlierBudgets.filter {
            calendar.isDate($0.monthStart, equalTo: sourceMonthStart, toGranularity: .month)
        }
        var currentCategories = Set(currentMonthBudgets.map(\.category))
        var copiedBudget = false

        for sourceBudget in sourceBudgets where !currentCategories.contains(sourceBudget.category) {
            modelContext.insert(
                Budget(
                    category: sourceBudget.category,
                    monthStart: currentMonthStart,
                    amount: sourceBudget.amount
                )
            )
            currentCategories.insert(sourceBudget.category)
            copiedBudget = true
        }

        if copiedBudget {
            try? modelContext.save()
        }
    }
}

private struct BudgetGettingStartedCard: View {
    let onSetBudget: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "target")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text("Set your first budget")
                    .font(.headline)

                Text("Choose a monthly amount for a category to start tracking your plan.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onSetBudget) {
                    Label("Set budget", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.blue.opacity(0.14), lineWidth: 1)
        }
    }
}

private struct BudgetDraft: Identifiable {
    let category: CategoryKind
    let amount: Decimal

    var id: String { category.rawValue }
}

private struct BudgetSummary {
    let totalBudget: Decimal
    let totalIncome: Decimal
    let totalExpenses: Decimal

    init(rows: [BudgetCategoryRow]) {
        totalBudget = rows.reduce(.zero) { $0 + $1.budgetAmount }
        totalIncome = rows.reduce(.zero) { $0 + $1.incomeAmount }
        totalExpenses = rows.reduce(.zero) { $0 + $1.expenseAmount }
    }

    var remaining: Decimal {
        totalBudget + totalIncome - totalExpenses
    }
}

private struct BudgetCategoryRow: Identifiable {
    let category: CategoryKind
    let categoryTitle: String
    let systemImage: String
    let tint: Color
    let budgetAmount: Decimal
    let incomeAmount: Decimal
    let expenseAmount: Decimal

    var id: String { category.rawValue }
    var isIncomeGoal: Bool { category == .income || category == .refund }
    var netSpentAmount: Decimal { expenseAmount - incomeAmount }
    var remainingAmount: Decimal {
        isIncomeGoal ? budgetAmount - incomeAmount : budgetAmount - netSpentAmount
    }
    var displayedAmount: Decimal {
        isIncomeGoal ? incomeAmount : remainingAmount
    }
    var progress: Double {
        guard budgetAmount > .zero else { return 0 }
        let currentAmount = isIncomeGoal ? incomeAmount : max(netSpentAmount, .zero)
        let current = NSDecimalNumber(decimal: currentAmount).doubleValue
        let budget = NSDecimalNumber(decimal: budgetAmount).doubleValue
        return min(max(current / budget, 0), 1)
    }
}

private struct BudgetSummarySection: View {
    let summary: BudgetSummary

    var body: some View {
        VStack(spacing: 12) {
            BudgetRemainingHero(value: summary.remaining)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                BudgetMetricCard(title: "Budget", value: summary.totalBudget, systemImage: "target", tint: .blue)
                BudgetMetricCard(title: "Income", value: summary.totalIncome, systemImage: "arrow.down.circle", tint: .green)
                BudgetMetricCard(title: "Expenses", value: summary.totalExpenses, systemImage: "creditcard", tint: .red)
            }
        }
    }
}

private struct BudgetRemainingHero: View {
    let value: Decimal

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Remaining", systemImage: "banknote.fill")
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

            Image(systemName: value >= .zero ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .accessibilityHidden(true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 124, alignment: .leading)
        .background {
            LinearGradient(
                colors: value >= .zero ? [Color.blue, Color.indigo] : [Color.orange, Color.red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: (value >= .zero ? Color.blue : Color.red).opacity(0.16), radius: 10, y: 5)
        .accessibilityElement(children: .combine)
    }
}

private struct BudgetMetricCard: View {
    let title: LocalizedStringKey
    let value: Decimal
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .foregroundStyle(tint)

            Text(value.formattedCurrency)
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

private struct BudgetCategoryRowView: View {
    let row: BudgetCategoryRow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: row.systemImage)
                    .font(.headline)
                    .foregroundStyle(row.tint)
                    .frame(width: 38, height: 38)
                    .background(row.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(row.categoryTitle)
                        .font(.subheadline.weight(.semibold))
                    if row.isIncomeGoal {
                        Text("Income: \(row.incomeAmount.formattedCurrency) · Budget: \(row.budgetAmount.formattedCurrency)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Income: \(row.incomeAmount.formattedCurrency)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Expenses: \(row.expenseAmount.formattedCurrency) · Budget: \(row.budgetAmount.formattedCurrency)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                Text(row.displayedAmount.formattedCurrency)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(row.isIncomeGoal ? Color.green : (row.remainingAmount >= .zero ? Color.primary : Color.red))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            ProgressView(value: row.progress)
                .tint(row.isIncomeGoal ? .green : (row.remainingAmount >= .zero ? .blue : .red))
                .scaleEffect(x: 1, y: 1.35, anchor: .center)
        }
        .padding(12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(row.tint.opacity(0.10), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct BudgetFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    let category: CategoryKind
    let amount: Decimal
    let onSave: (CategoryKind, Decimal) -> Void

    @State private var amountText: String

    init(category: CategoryKind, amount: Decimal, onSave: @escaping (CategoryKind, Decimal) -> Void) {
        self.category = category
        self.amount = amount
        self.onSave = onSave
        _amountText = State(initialValue: amount > .zero ? amount.formattedPlainAmount : "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Label(category.localizedTitle(locale: locale), systemImage: category.systemImage)
                }

                Section("Monthly budget") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Set budget")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let parsedAmount else { return }
                        onSave(category, parsedAmount)
                        dismiss()
                    }
                    .disabled(parsedAmount == nil)
                }
            }
        }
    }

    private var parsedAmount: Decimal? {
        let trimmed = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .zero }

        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        let groupingSeparator = Locale.current.groupingSeparator ?? ","
        let normalized = trimmed
            .replacingOccurrences(of: groupingSeparator, with: "")
            .replacingOccurrences(of: decimalSeparator, with: ".")
            .replacingOccurrences(of: ",", with: ".")

        guard let amount = Decimal(string: normalized), amount >= .zero else {
            return nil
        }

        return amount
    }
}

private extension Array where Element == Transaction {
    var totalAmount: Decimal {
        reduce(Decimal.zero) { partialResult, transaction in
            partialResult + transaction.amount
        }
    }
}

private extension Decimal {
    var formattedPlainAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: self)) ?? ""
    }
}

#Preview {
    BudgetsView()
        .environment(ProPurchaseStore())
}
