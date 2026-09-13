//
//  TransactionsView.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import SwiftData
import SwiftUI

struct TransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.dueDate) private var transactions: [Transaction]

    @State private var selectedFilter: TransactionListFilter = .all
    @State private var editingTransaction: Transaction?
    @State private var isShowingEditForm = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TransactionFilterPicker(selectedFilter: $selectedFilter)

                if filteredTransactions.isEmpty {
                    TransactionEmptyState(filter: selectedFilter)
                } else {
                    List {
                        ForEach(filteredTransactions, id: \.id) { transaction in
                            NavigationLink {
                                TransactionDetailView(transaction: transaction)
                            } label: {
                                TransactionRowView(transaction: transaction)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    markCompleted(transaction)
                                } label: {
                                    Label("Mark paid", systemImage: "checkmark.circle")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(transaction)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    duplicate(transaction)
                                } label: {
                                    Label("Duplicate", systemImage: "plus.square.on.square")
                                }
                                .tint(.blue)

                                Button {
                                    edit(transaction)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Transactions")
            .sheet(isPresented: $isShowingEditForm, onDismiss: { editingTransaction = nil }) {
                if let editingTransaction {
                    TransactionFormView(transaction: editingTransaction)
                }
            }
        }
    }

    private var activeTransactions: [Transaction] {
        transactions.filter { !$0.isArchived && $0.status != .cancelled }
    }

    private var filteredTransactions: [Transaction] {
        activeTransactions.filter { selectedFilter.includes($0) }
    }

    private func markCompleted(_ transaction: Transaction) {
        transaction.paidDate = .now
        transaction.isCompleted = true
        transaction.status = transaction.type == .income ? .received : .paid
        transaction.markUpdated()
    }

    private func duplicate(_ transaction: Transaction) {
        let copy = Transaction(
            title: "\(transaction.title) copy",
            amount: transaction.amount,
            type: transaction.type,
            dueDate: transaction.dueDate,
            paidDate: transaction.paidDate,
            status: transaction.status,
            category: transaction.category,
            recurrence: transaction.recurrence,
            recurrenceIntervalMonths: transaction.recurrenceIntervalMonths,
            notes: transaction.notes,
            isCompleted: transaction.isCompleted,
            isArchived: transaction.isArchived
        )
        modelContext.insert(copy)
    }

    private func edit(_ transaction: Transaction) {
        editingTransaction = transaction
        isShowingEditForm = true
    }

    private func delete(_ transaction: Transaction) {
        modelContext.delete(transaction)
    }
}

private enum TransactionListFilter: String, CaseIterable, Identifiable {
    case all
    case overdue
    case upcoming
    case completed
    case receivable

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .all:
            "All"
        case .overdue:
            "Overdue"
        case .upcoming:
            "Upcoming"
        case .completed:
            "Paid"
        case .receivable:
            "Receivable"
        }
    }

    func includes(_ transaction: Transaction) -> Bool {
        switch self {
        case .all:
            true
        case .overdue:
            transaction.effectiveStatus == .overdue
        case .upcoming:
            transaction.status == .pending && !transaction.isCompleted && !isPastDue(transaction.dueDate)
        case .completed:
            transaction.isCompleted || transaction.status == .paid || transaction.status == .received
        case .receivable:
            transaction.type == .income && transaction.status == .pending && !transaction.isCompleted
        }
    }

    private func isPastDue(_ date: Date) -> Bool {
        date < Calendar.current.startOfDay(for: .now)
    }
}

private struct TransactionFilterPicker: View {
    @Binding var selectedFilter: TransactionListFilter

    var body: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(TransactionListFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

private struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            TransactionTypeIcon(type: transaction.type)

            VStack(alignment: .leading, spacing: 6) {
                Text(transaction.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Label(transaction.category?.name ?? String(localized: "No category"), systemImage: transaction.category?.icon ?? "tag")
                    Text("Due \(transaction.dueDate, format: .dateTime.day().month().year())")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

                HStack(spacing: 8) {
                    TransactionStatusBadge(status: transaction.effectiveStatus)
                    TransactionTypeBadge(type: transaction.type)
                }
            }

            Spacer(minLength: 8)

            Text(transaction.amount.formattedCurrency)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(transaction.type == .income ? .green : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

private struct TransactionTypeIcon: View {
    let type: TransactionType

    var body: some View {
        Image(systemName: type == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
            .font(.title2)
            .foregroundStyle(type == .income ? .green : .red)
            .frame(width: 32, height: 32)
            .accessibilityHidden(true)
    }
}

private struct TransactionStatusBadge: View {
    let status: TransactionStatus

    var body: some View {
        Text(status.title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(status.tint)
            .background(status.tint.opacity(0.12))
            .clipShape(Capsule())
    }
}

private struct TransactionTypeBadge: View {
    let type: TransactionType

    var body: some View {
        Text(type.title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(.secondary)
            .background(.secondary.opacity(0.12))
            .clipShape(Capsule())
    }
}

private struct TransactionEmptyState: View {
    let filter: TransactionListFilter

    var body: some View {
        ContentUnavailableView(
            "No transactions",
            systemImage: "list.bullet.rectangle",
            description: Text(emptyDescription)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyDescription: LocalizedStringKey {
        switch filter {
        case .all:
            "New transactions will appear here."
        case .overdue:
            "Overdue transactions will appear here."
        case .upcoming:
            "Upcoming transactions will appear here."
        case .completed:
            "Paid and received transactions will appear here."
        case .receivable:
            "Pending income will appear here."
        }
    }
}

private struct TransactionDetailView: View {
    let transaction: Transaction

    var body: some View {
        List {
            Section("Transaction") {
                LabeledContent("Title", value: transaction.title)
                LabeledContent("Amount", value: transaction.amount.formattedCurrency)
                LabeledContent("Type") {
                    Text(transaction.type.title)
                }
                LabeledContent("Status") {
                    Text(transaction.effectiveStatus.title)
                }
            }

            Section("Dates") {
                LabeledContent("Due date") {
                    Text(transaction.dueDate, format: .dateTime.day().month().year())
                }

                if let paidDate = transaction.paidDate {
                    LabeledContent("Paid date") {
                        Text(paidDate, format: .dateTime.day().month().year())
                    }
                }
            }

            Section("Category") {
                Label(transaction.category?.name ?? String(localized: "No category"), systemImage: transaction.category?.icon ?? "tag")
            }

            if !transaction.notes.isEmpty {
                Section("Notes") {
                    Text(transaction.notes)
                }
            }
        }
        .navigationTitle(transaction.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension TransactionStatus {
    var tint: Color {
        switch self {
        case .pending:
            .orange
        case .overdue:
            .red
        case .paid, .received:
            .green
        case .cancelled:
            .secondary
        }
    }
}

#Preview {
    TransactionsView()
}
