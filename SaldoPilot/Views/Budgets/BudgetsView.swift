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

    @State private var selectedCategory: CategoryKind?
    @State private var selectedAmount: Decimal = .zero
    @State private var isShowingBudgetForm = false
    @State private var isShowingProInfo = false

    var body: some View {
        NavigationStack {
            Group {
                if proPurchaseStore.isProUnlocked {
                    budgetContent
                } else {
                    proLockedContent
                }
            }
            .navigationTitle("Budgets")
            .toolbar {
                if proPurchaseStore.isProUnlocked {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            openBudgetForm(category: .home)
                        } label: {
                            Label("Set budget", systemImage: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingBudgetForm) {
                if let selectedCategory {
                    BudgetFormView(
                        category: selectedCategory,
                        amount: selectedAmount,
                        onSave: saveBudget
                    )
                }
            }
            .sheet(isPresented: $isShowingProInfo) {
                NavigationStack {
                    ProInfoView()
                }
            }
            .task {
                await proPurchaseStore.refresh()
            }
        }
    }

    private var budgetContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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

    private var currentMonthExpenses: [Transaction] {
        transactions.filter { transaction in
            !transaction.isArchived &&
            transaction.status != .cancelled &&
            transaction.type == .expense &&
            currentMonthInterval.contains(transaction.dueDate)
        }
    }

    private var budgetRows: [BudgetCategoryRow] {
        CategoryKind.sortedForDisplay(locale: locale).map { category in
            let budget = currentMonthBudgets.first { $0.category == category }
            let spent = currentMonthExpenses
                .filter { $0.category == category }
                .totalAmount
            return BudgetCategoryRow(
                category: category,
                categoryTitle: category.localizedTitle(locale: locale),
                systemImage: category.systemImage,
                budgetAmount: budget?.amount ?? .zero,
                spentAmount: spent
            )
        }
    }

    private var budgetSummary: BudgetSummary {
        BudgetSummary(rows: budgetRows)
    }

    private func openBudgetForm(category: CategoryKind) {
        selectedCategory = category
        selectedAmount = currentMonthBudgets.first { $0.category == category }?.amount ?? .zero
        isShowingBudgetForm = true
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
    }
}

private struct BudgetSummary {
    let totalBudget: Decimal
    let totalSpent: Decimal

    init(rows: [BudgetCategoryRow]) {
        totalBudget = rows.reduce(.zero) { $0 + $1.budgetAmount }
        totalSpent = rows.reduce(.zero) { $0 + $1.spentAmount }
    }

    var remaining: Decimal {
        totalBudget - totalSpent
    }
}

private struct BudgetCategoryRow: Identifiable {
    let category: CategoryKind
    let categoryTitle: String
    let systemImage: String
    let budgetAmount: Decimal
    let spentAmount: Decimal

    var id: String { category.rawValue }
    var remainingAmount: Decimal { budgetAmount - spentAmount }
    var progress: Double {
        guard budgetAmount > .zero else { return 0 }
        let spent = NSDecimalNumber(decimal: spentAmount).doubleValue
        let budget = NSDecimalNumber(decimal: budgetAmount).doubleValue
        return min(max(spent / budget, 0), 1)
    }
}

private struct BudgetSummarySection: View {
    let summary: BudgetSummary

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
            BudgetMetricCard(title: "Budget", value: summary.totalBudget, systemImage: "target", tint: .blue)
            BudgetMetricCard(title: "Spent", value: summary.totalSpent, systemImage: "creditcard", tint: .red)
            BudgetMetricCard(title: "Remaining", value: summary.remaining, systemImage: "banknote", tint: summary.remaining >= .zero ? .green : .red)
        }
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
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(row.categoryTitle)
                        .font(.subheadline.weight(.semibold))
                    Text("Spent \(row.spentAmount.formattedCurrency) of \(row.budgetAmount.formattedCurrency)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text(row.remainingAmount.formattedCurrency)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(row.remainingAmount >= .zero ? Color.primary : Color.red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            ProgressView(value: row.progress)
                .tint(row.remainingAmount >= .zero ? .blue : .red)
        }
        .padding(12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary, lineWidth: 1)
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
