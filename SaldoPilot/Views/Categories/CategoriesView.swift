//
//  CategoriesView.swift
//  SaldoPilot
//
//  Created by Terje Moe on 13/09/2026.
//

import SwiftData
import SwiftUI

struct CategoriesView: View {
    @Environment(\.locale) private var locale

    @Query(sort: \Transaction.dueDate) private var transactions: [Transaction]

    @State private var selectedPeriod: CategoryPeriod = .thisMonth

    var body: some View {
        List {
            Section {
                CategoryPeriodPicker(selectedPeriod: $selectedPeriod)
            }

            Section("Standard categories") {
                ForEach(CategoryKind.sortedForDisplay(locale: locale)) { category in
                    CategoryRowView(
                        category: category,
                        transactionCount: transactionCount(for: category),
                        periodAmount: periodAmount(for: category)
                    )
                }
            }

            Section("About categories") {
                Text("SaldoPilot uses a small fixed category set so names stay translated across Norwegian, English and Thai.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Categories")
    }

    private var periodInterval: DateInterval? {
        selectedPeriod.interval(calendar: .current)
    }

    private func transactionCount(for category: CategoryKind) -> Int {
        transactions.filter { $0.category == category && !$0.isArchived }.count
    }

    private func periodAmount(for category: CategoryKind) -> Decimal {
        transactions
            .filter { transaction in
                transaction.category == category &&
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
    let category: CategoryKind
    let transactionCount: Int
    let periodAmount: Decimal

    var body: some View {
        HStack(spacing: 12) {
            CategoryIconView(category: category)

            VStack(alignment: .leading, spacing: 4) {
                Text(category.title)
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
    let category: CategoryKind

    var body: some View {
        Image(systemName: category.systemImage)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(category.tint.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityHidden(true)
    }
}

#Preview {
    CategoriesView()
}
