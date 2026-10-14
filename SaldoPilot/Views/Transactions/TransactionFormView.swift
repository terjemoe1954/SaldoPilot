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
    @Query(sort: \Transaction.dueDate) private var transactions: [Transaction]
    @AppStorage(AppSettingsKey.openingBalanceAmount) private var openingBalanceAmountText = ""
    @AppStorage(AppSettingsKey.openingBalanceDate) private var openingBalanceDateTimestamp = Date.now.timeIntervalSince1970

    private let transaction: Transaction?

    @State private var title: String
    @State private var amountText: String
    @State private var type: TransactionType
    @State private var category: CategoryKind
    @State private var dueDate: Date
    @State private var hasPaidDate: Bool
    @State private var paidDate: Date
    @State private var status: TransactionStatus
    @State private var recurrence: RecurrenceRule
    @State private var recurrenceIntervalMonths: Int
    @State private var notes: String
    @State private var isShowingRecurrenceScopeDialog = false
    @State private var isShowingCoverageWarning = false
    @State private var pendingCoverageScope: RecurrenceUpdateScope?
    @State private var allowsInsufficientCoverage = false

    init(transaction: Transaction? = nil, intent: NewTransactionIntent = .transaction) {
        self.transaction = transaction

        let initialType = transaction?.type ?? intent.initialType
        let initialStatus = transaction?.status ?? intent.initialStatus(for: initialType)
        let initialPaidDate = transaction?.paidDate ?? .now

        _title = State(initialValue: transaction?.title ?? "")
        _amountText = State(initialValue: transaction.map { Self.amountFormatter.string(from: NSDecimalNumber(decimal: $0.amount)) ?? "" } ?? "")
        _type = State(initialValue: initialType)
        _category = State(initialValue: transaction?.category ?? (initialType == .income ? .income : .other))
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

                TransactionCategorySection(category: $category)

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
                        requestSave()
                    }
                    .disabled(!canSave)
                }
            }
            .confirmationDialog(
                "Update recurring transactions?",
                isPresented: $isShowingRecurrenceScopeDialog,
                titleVisibility: .visible
            ) {
                Button("Only this transaction") {
                    save(scope: .single)
                }
                Button("This and future transactions") {
                    save(scope: .thisAndFuture)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Choose whether the change should apply only to this transaction or also to matching future transactions.")
            }
            .confirmationDialog(
                "Not enough registered balance",
                isPresented: $isShowingCoverageWarning,
                titleVisibility: .visible
            ) {
                Button("Keep pending", role: .cancel) {
                    pendingCoverageScope = nil
                }
                Button("Register as paid anyway", role: .destructive) {
                    guard let pendingCoverageScope else { return }
                    allowsInsufficientCoverage = true
                    save(scope: pendingCoverageScope)
                    self.pendingCoverageScope = nil
                }
            } message: {
                Text("SaldoPilot does not have enough registered available balance for this payment. The bank's actual balance may differ.")
            }
            .onChange(of: title) { _, newTitle in
                updateSuggestedCategory(for: newTitle)
            }
            .onChange(of: type) { _, newType in
                if transaction == nil && category == .other {
                    category = newType == .income ? .income : .other
                }

                if status == .paid || status == .received {
                    status = newType == .income ? .received : .paid
                }
            }
            .onChange(of: status) { _, newStatus in
                if newStatus == .paid || newStatus == .received {
                    hasPaidDate = true
                }
            }
            .onChange(of: hasPaidDate) { _, newValue in
                if !newValue && (status == .paid || status == .received) {
                    status = .pending
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

    private func updateSuggestedCategory(for title: String) {
        guard category == .other else { return }
        if let suggestedCategory = CategoryKind.allCases.first(where: { $0 != .other && $0.matches(transactionTitle: title) }) {
            category = suggestedCategory
        }
    }

    private func requestSave() {
        guard shouldAskForRecurringUpdate else {
            save(scope: .single)
            return
        }

        isShowingRecurrenceScopeDialog = true
    }

    private var shouldAskForRecurringUpdate: Bool {
        guard let transaction, transaction.recurrence != .none else {
            return false
        }

        let snapshot = RecurrenceService.SeriesSnapshot(transaction: transaction)
        return !RecurrenceService.futureOccurrences(matching: snapshot, in: transactions).isEmpty
    }

    private func save(scope: RecurrenceUpdateScope) {
        guard let amount = parsedAmount else { return }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedPaidDate = hasPaidDate ? paidDate : nil
        let resolvedStatus: TransactionStatus
        if resolvedPaidDate != nil {
            resolvedStatus = completedStatus(for: type)
        } else if status == .paid || status == .received {
            resolvedStatus = .pending
        } else {
            resolvedStatus = status
        }
        let resolvedIsCompleted = resolvedStatus == .paid || resolvedStatus == .received

        if !allowsInsufficientCoverage,
           resolvedIsCompleted,
           type == .expense,
           transaction?.isSettled != true,
           let availableBalance,
           amount > availableBalance {
            pendingCoverageScope = scope
            isShowingCoverageWarning = true
            return
        }

        let resolvedInterval = recurrence == .everyNMonths || recurrence == .custom ? recurrenceIntervalMonths : nil

        if let transaction {
            let seriesSnapshot = RecurrenceService.SeriesSnapshot(transaction: transaction)
            let futureOccurrences = RecurrenceService.futureOccurrences(matching: seriesSnapshot, in: transactions)
            let wasCompleted = transaction.isCompleted || transaction.status == .paid || transaction.status == .received
            transaction.title = trimmedTitle
            transaction.amount = amount
            transaction.type = type
            transaction.dueDate = dueDate
            transaction.paidDate = resolvedPaidDate
            transaction.status = resolvedStatus
            transaction.category = category
            transaction.recurrence = recurrence
            transaction.recurrenceIntervalMonths = resolvedInterval
            transaction.notes = notes
            transaction.isCompleted = resolvedIsCompleted
            transaction.markUpdated()

            if !wasCompleted && resolvedIsCompleted {
                RecurrenceService.insertNextOccurrenceIfNeeded(after: transaction, in: modelContext)
            }

            if scope == .thisAndFuture {
                RecurrenceService.applyTemplate(from: transaction, toFutureOccurrences: futureOccurrences)
            }
        } else {
            let newTransaction = Transaction(
                title: trimmedTitle,
                amount: amount,
                type: type,
                dueDate: dueDate,
                paidDate: resolvedPaidDate,
                status: resolvedStatus,
                category: category,
                recurrence: recurrence,
                recurrenceIntervalMonths: resolvedInterval,
                notes: notes,
                isCompleted: resolvedIsCompleted
            )
            modelContext.insert(newTransaction)

            if resolvedIsCompleted {
                RecurrenceService.insertNextOccurrenceIfNeeded(after: newTransaction, in: modelContext)
            }
        }

        dismiss()
    }

    private var availableBalance: Decimal? {
        AccountBalanceCalculator.availableBalance(
            openingBalanceText: openingBalanceAmountText,
            openingBalanceDate: Date(timeIntervalSince1970: openingBalanceDateTimestamp),
            transactions: transactions
        )
    }

    private func completedStatus(for type: TransactionType) -> TransactionStatus {
        type == .income ? .received : .paid
    }

    private static let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static func parseAmount(_ value: String) -> Decimal? {
        Decimal.currencyAmount(from: value)
    }
}

private enum RecurrenceUpdateScope {
    case single
    case thisAndFuture
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
    @Environment(\.locale) private var locale

    @Binding var category: CategoryKind

    var body: some View {
        Section("Category") {
            Picker("Category", selection: $category) {
                ForEach(CategoryKind.sortedForDisplay(locale: locale)) { category in
                    Label(category.title, systemImage: category.systemImage)
                        .tag(category)
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
                    LabeledContent("Interval") {
                        Text("Every \(recurrenceIntervalMonths) months")
                    }
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
        case .income, .transaction, .expense:
            .pending
        }
    }
}
