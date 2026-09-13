//
//  TransactionFormView.swift
//  SaldoPilot
//
//  Created by Terje Moe on 13/09/2026.
//

import SwiftData
import SwiftUI

struct TransactionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]

    private let transaction: Transaction?

    @State private var title: String
    @State private var amountText: String
    @State private var type: TransactionType
    @State private var selectedCategoryID: UUID?
    @State private var dueDate: Date
    @State private var hasPaidDate: Bool
    @State private var paidDate: Date
    @State private var status: TransactionStatus
    @State private var recurrence: RecurrenceRule
    @State private var recurrenceIntervalMonths: Int
    @State private var notes: String

    init(transaction: Transaction? = nil, intent: NewTransactionIntent = .transaction) {
        self.transaction = transaction

        let initialType = transaction?.type ?? intent.initialType
        let initialStatus = transaction?.status ?? intent.initialStatus(for: initialType)
        let initialPaidDate = transaction?.paidDate ?? .now

        _title = State(initialValue: transaction?.title ?? "")
        _amountText = State(initialValue: transaction.map { Self.amountFormatter.string(from: NSDecimalNumber(decimal: $0.amount)) ?? "" } ?? "")
        _type = State(initialValue: initialType)
        _selectedCategoryID = State(initialValue: transaction?.category?.id)
        _dueDate = State(initialValue: transaction?.dueDate ?? .now)
        _hasPaidDate = State(initialValue: transaction?.paidDate != nil || initialStatus == .paid || initialStatus == .received)
        _paidDate = State(initialValue: initialPaidDate)
        _status = State(initialValue: initialStatus)
        _recurrence = State(initialValue: transaction?.recurrence ?? .none)
        _recurrenceIntervalMonths = State(initialValue: transaction?.recurrenceIntervalMonths ?? 1)
        _notes = State(initialValue: transaction?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TransactionBasicsSection(
                    title: $title,
                    amountText: $amountText,
                    type: $type
                )

                TransactionCategorySection(
                    categories: categories,
                    selectedCategoryID: $selectedCategoryID
                )

                TransactionDatesSection(
                    dueDate: $dueDate,
                    hasPaidDate: $hasPaidDate,
                    paidDate: $paidDate,
                    status: $status
                )

                TransactionRecurrenceSection(
                    recurrence: $recurrence,
                    recurrenceIntervalMonths: $recurrenceIntervalMonths
                )

                Section("Note") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 96)
                }
            }
            .navigationTitle(transaction == nil ? "New transaction" : "Edit transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
            .onChange(of: type) { _, newType in
                if status == .paid || status == .received {
                    status = newType == .income ? .received : .paid
                }
            }
            .onChange(of: status) { _, newStatus in
                if newStatus == .paid || newStatus == .received {
                    hasPaidDate = true
                }
            }
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedAmount != nil
    }

    private var parsedAmount: Decimal? {
        Self.parseAmount(amountText)
    }

    private var selectedCategory: Category? {
        guard let selectedCategoryID else { return nil }
        return categories.first { $0.id == selectedCategoryID }
    }

    private func save() {
        guard let amount = parsedAmount else { return }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedPaidDate = hasPaidDate ? paidDate : nil
        let resolvedIsCompleted = status == .paid || status == .received
        let resolvedInterval = recurrence == .everyNMonths || recurrence == .custom ? recurrenceIntervalMonths : nil

        if let transaction {
            transaction.title = trimmedTitle
            transaction.amount = amount
            transaction.type = type
            transaction.dueDate = dueDate
            transaction.paidDate = resolvedPaidDate
            transaction.status = status
            transaction.category = selectedCategory
            transaction.recurrence = recurrence
            transaction.recurrenceIntervalMonths = resolvedInterval
            transaction.notes = notes
            transaction.isCompleted = resolvedIsCompleted
            transaction.markUpdated()
        } else {
            let newTransaction = Transaction(
                title: trimmedTitle,
                amount: amount,
                type: type,
                dueDate: dueDate,
                paidDate: resolvedPaidDate,
                status: status,
                category: selectedCategory,
                recurrence: recurrence,
                recurrenceIntervalMonths: resolvedInterval,
                notes: notes,
                isCompleted: resolvedIsCompleted
            )
            modelContext.insert(newTransaction)
        }

        dismiss()
    }

    private static let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static func parseAmount(_ value: String) -> Decimal? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        let groupingSeparator = Locale.current.groupingSeparator ?? ","
        let normalized = trimmed
            .replacingOccurrences(of: groupingSeparator, with: "")
            .replacingOccurrences(of: decimalSeparator, with: ".")
            .replacingOccurrences(of: ",", with: ".")

        guard let amount = Decimal(string: normalized), amount > .zero else {
            return nil
        }

        return amount
    }
}

private struct TransactionBasicsSection: View {
    @Binding var title: String
    @Binding var amountText: String
    @Binding var type: TransactionType

    var body: some View {
        Section("Transaction") {
            TextField("Title", text: $title)
                .textInputAutocapitalization(.sentences)

            TextField("Amount", text: $amountText)
                .keyboardType(.decimalPad)

            Picker("Type", selection: $type) {
                ForEach(TransactionType.allCases) { transactionType in
                    Text(transactionType.title).tag(transactionType)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

private struct TransactionCategorySection: View {
    let categories: [Category]
    @Binding var selectedCategoryID: UUID?

    var body: some View {
        Section("Category") {
            Picker("Category", selection: $selectedCategoryID) {
                Label("No category", systemImage: "tag")
                    .tag(Optional<UUID>.none)

                ForEach(categories, id: \.id) { category in
                    Label(category.name, systemImage: category.icon)
                        .tag(Optional(category.id))
                }
            }
        }
    }
}

private struct TransactionDatesSection: View {
    @Binding var dueDate: Date
    @Binding var hasPaidDate: Bool
    @Binding var paidDate: Date
    @Binding var status: TransactionStatus

    var body: some View {
        Section("Dates") {
            DatePicker("Due date", selection: $dueDate, displayedComponents: .date)

            Toggle("Paid or received", isOn: $hasPaidDate)

            if hasPaidDate {
                DatePicker("Paid date", selection: $paidDate, displayedComponents: .date)
            }

            Picker("Status", selection: $status) {
                ForEach(TransactionStatus.allCases) { transactionStatus in
                    Text(transactionStatus.title).tag(transactionStatus)
                }
            }
        }
    }
}

private struct TransactionRecurrenceSection: View {
    @Binding var recurrence: RecurrenceRule
    @Binding var recurrenceIntervalMonths: Int

    var body: some View {
        Section("Recurrence") {
            Picker("Recurrence", selection: $recurrence) {
                ForEach(RecurrenceRule.allCases) { recurrenceRule in
                    Text(recurrenceRule.title).tag(recurrenceRule)
                }
            }

            if recurrence == .everyNMonths || recurrence == .custom {
                Stepper(value: $recurrenceIntervalMonths, in: 1...60) {
                    LabeledContent("Interval", value: "\(recurrenceIntervalMonths) months")
                }
            }
        }
    }
}

private extension NewTransactionIntent {
    var initialType: TransactionType {
        switch self {
        case .income:
            .income
        case .transaction, .expense, .payment:
            .expense
        }
    }

    func initialStatus(for type: TransactionType) -> TransactionStatus {
        switch self {
        case .payment:
            type == .income ? .received : .paid
        case .transaction, .income, .expense:
            .pending
        }
    }
}

#Preview {
    TransactionFormView()
}
