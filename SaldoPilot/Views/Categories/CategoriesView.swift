//
//  CategoriesView.swift
//  SaldoPilot
//
//  Created by Terje Moe on 13/09/2026.
//

import SwiftData
import SwiftUI

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Transaction.dueDate) private var transactions: [Transaction]

    @State private var selectedPeriod: CategoryPeriod = .thisMonth
    @State private var isShowingNewCategory = false
    @State private var editingCategory: Category?
    @State private var deletingCategory: Category?

    var body: some View {
        List {
            Section {
                CategoryPeriodPicker(selectedPeriod: $selectedPeriod)
            }

            if categories.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No categories",
                        systemImage: "tag",
                        description: Text("Create categories to organize income and expenses.")
                    )
                }
            } else {
                Section("Categories") {
                    ForEach(categories, id: \.id) { category in
                        CategoryRowView(
                            category: category,
                            transactionCount: transactionCount(for: category),
                            periodAmount: periodAmount(for: category)
                        )
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deletingCategory = category
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                editingCategory = category
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingNewCategory = true
                } label: {
                    Label("New category", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingNewCategory) {
            CategoryFormView()
        }
        .sheet(item: $editingCategory) { category in
            CategoryFormView(category: category)
        }
        .sheet(item: $deletingCategory) { category in
            CategoryDeleteView(
                category: category,
                categories: categories.filter { $0.id != category.id },
                affectedTransactions: transactions.filter { $0.category?.id == category.id }
            )
        }
    }

    private var periodInterval: DateInterval? {
        selectedPeriod.interval(calendar: .current)
    }

    private func transactionCount(for category: Category) -> Int {
        transactions.filter { $0.category?.id == category.id && !$0.isArchived }.count
    }

    private func periodAmount(for category: Category) -> Decimal {
        transactions
            .filter { transaction in
                transaction.category?.id == category.id &&
                !transaction.isArchived &&
                transaction.status != .cancelled &&
                selectedPeriod.includes(transaction.dueDate, interval: periodInterval)
            }
            .reduce(Decimal.zero) { runningTotal, transaction in
                switch transaction.type {
                case .income:
                    runningTotal + transaction.amount
                case .expense:
                    runningTotal - transaction.amount
                }
            }
    }
}

private enum CategoryPeriod: String, CaseIterable, Identifiable {
    case thisMonth
    case thisYear
    case allTime

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .thisMonth:
            "This month"
        case .thisYear:
            "This year"
        case .allTime:
            "All time"
        }
    }

    func interval(calendar: Calendar) -> DateInterval? {
        switch self {
        case .thisMonth:
            calendar.dateInterval(of: .month, for: .now)
        case .thisYear:
            calendar.dateInterval(of: .year, for: .now)
        case .allTime:
            nil
        }
    }

    func includes(_ date: Date, interval: DateInterval?) -> Bool {
        guard let interval else { return true }
        return interval.contains(date)
    }
}

private struct CategoryPeriodPicker: View {
    @Binding var selectedPeriod: CategoryPeriod

    var body: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(CategoryPeriod.allCases) { period in
                Text(period.title).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
}

private struct CategoryRowView: View {
    let category: Category
    let transactionCount: Int
    let periodAmount: Decimal

    var body: some View {
        HStack(spacing: 12) {
            CategoryIconView(
                icon: category.icon,
                colorIdentifier: category.colorIdentifier
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)

                Text("\(transactionCount) transactions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(periodAmount.formattedCurrency)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(periodAmount < .zero ? .red : .green)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

struct CategoryIconView: View {
    let icon: String
    let colorIdentifier: String?

    var body: some View {
        Image(systemName: icon)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(CategoryColor.color(for: colorIdentifier))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityHidden(true)
    }
}

private struct CategoryDeleteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let category: Category
    let categories: [Category]
    let affectedTransactions: [Transaction]

    @State private var selectedDestinationID: UUID?

    var body: some View {
        NavigationStack {
            Form {
                Section("Affected transactions") {
                    Text("\(affectedTransactions.count) transactions use this category.")
                }

                Section("Move transactions") {
                    if categories.isEmpty {
                        ContentUnavailableView(
                            "No other categories",
                            systemImage: "tag",
                            description: Text("You can keep the transactions and remove their category instead.")
                        )
                    } else {
                        Picker("Destination", selection: $selectedDestinationID) {
                            Text("Choose category").tag(Optional<UUID>.none)
                            ForEach(categories, id: \.id) { category in
                                Text(category.name).tag(Optional(category.id))
                            }
                        }

                        Button("Move to selected category") {
                            moveTransactionsToSelectedCategory()
                        }
                        .disabled(selectedDestinationID == nil)
                    }
                }

                Section("Keep transactions") {
                    Button("Remove category from transactions") {
                        removeCategoryFromTransactions()
                    }
                }

                Section("Danger zone") {
                    Button("Delete category and transactions", role: .destructive) {
                        deleteCategoryAndTransactions()
                    }
                }
            }
            .navigationTitle("Delete category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func moveTransactionsToSelectedCategory() {
        guard let selectedDestinationID,
              let destination = categories.first(where: { $0.id == selectedDestinationID }) else {
            return
        }

        affectedTransactions.forEach { transaction in
            transaction.category = destination
            transaction.markUpdated()
        }
        modelContext.delete(category)
        dismiss()
    }

    private func removeCategoryFromTransactions() {
        affectedTransactions.forEach { transaction in
            transaction.category = nil
            transaction.markUpdated()
        }
        modelContext.delete(category)
        dismiss()
    }

    private func deleteCategoryAndTransactions() {
        affectedTransactions.forEach { transaction in
            modelContext.delete(transaction)
        }
        modelContext.delete(category)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        CategoriesView()
    }
}
