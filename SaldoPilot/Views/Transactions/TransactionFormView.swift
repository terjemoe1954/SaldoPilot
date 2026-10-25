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
    @Query(sort: \CategoryDefinition.name) private var categoryDefinitions: [CategoryDefinition]

    private let transaction: Transaction?

    @State private var title: String
    @State private var amountText: String
    @State private var type: TransactionType
    @State private var category: CategoryKind
    @State private var customCategoryID: String?
    @State private var dueDate: Date
    @State private var hasPaidDate: Bool
    @State private var paidDate: Date
    @State private var status: TransactionStatus
    @State private var recurrence: RecurrenceRule
    @State private var recurrenceIntervalMonths: Int
    @State private var notes: String
    @State private var isShowingRecurrenceScopeDialog = false
    @State private var isShowingSaveError = false
    @State private var suggestedCategory: CategoryKind?
    @State private var categoryWasManuallySelected: Bool
    @FocusState private var focusedField: TransactionFormField?

    init(transaction: Transaction? = nil, intent: NewTransactionIntent = .transaction) {
        self.transaction = transaction

        let initialType = transaction?.type ?? intent.initialType
        let initialStatus = transaction?.status ?? intent.initialStatus(for: initialType)
        let initialPaidDate = transaction?.paidDate ?? .now

        _title = State(initialValue: transaction?.title ?? "")
        _amountText = State(initialValue: transaction.map { Self.amountFormatter.string(from: NSDecimalNumber(decimal: $0.amount)) ?? "" } ?? "")
        _type = State(initialValue: initialType)
        _category = State(initialValue: transaction?.category ?? (initialType == .income ? .income : .other))
        _customCategoryID = State(initialValue: transaction?.customCategoryID)
        _dueDate = State(initialValue: transaction?.dueDate ?? .now)
        _hasPaidDate = State(initialValue: transaction?.paidDate != nil || initialStatus == .paid || initialStatus == .received)
        _paidDate = State(initialValue: initialPaidDate)
        _status = State(initialValue: initialStatus)
        _recurrence = State(initialValue: transaction?.recurrence ?? .none)
        _recurrenceIntervalMonths = State(initialValue: transaction?.recurrenceIntervalMonths ?? 1)
        _notes = State(initialValue: transaction?.notes ?? "")
        _suggestedCategory = State(initialValue: nil)
        _categoryWasManuallySelected = State(initialValue: transaction != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                TransactionDescriptionSection(
                    title: $title,
                    focusedField: $focusedField
                )

                TransactionCategorySection(
                    category: $category,
                    customCategoryID: $customCategoryID,
                    definitions: categoryDefinitions,
                    suggestedCategory: suggestedCategory,
                    onManualSelection: {
                        categoryWasManuallySelected = true
                        suggestedCategory = nil
                    }
                )

                TransactionAmountSection(
                    amountText: $amountText,
                    focusedField: $focusedField
                )

                TransactionDatesSection(
                    dueDate: $dueDate,
                    hasPaidDate: $hasPaidDate,
                    paidDate: $paidDate,
                    status: $status,
                    onPresentDatePicker: {
                        focusedField = nil
                    }
                )

                TransactionTypeSection(type: $type)

                TransactionRecurrenceSection(
                    recurrence: $recurrence,
                    recurrenceIntervalMonths: $recurrenceIntervalMonths
                )

                Section("Note") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 96)
                }
            }
            .scrollDismissesKeyboard(.interactively)
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
            .alert("Could not save transaction", isPresented: $isShowingSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The changes were not saved. Check the connection and try again.")
            }
            .onChange(of: title) { _, newTitle in
                updateSuggestedCategory(for: newTitle)
            }
            .task {
                updateSuggestedCategory(for: title)
            }
            .onChange(of: type) { _, newType in
                if transaction == nil && !categoryWasManuallySelected {
                    if newType == .income {
                        suggestedCategory = nil
                        category = .income
                        customCategoryID = nil
                    } else {
                        updateSuggestedCategory(for: title)
                    }
                }

                if status == .paid || status == .received {
                    status = newType == .income ? .received : .paid
                }
            }
            .onChange(of: dueDate) { _, newDueDate in
                suggestCompletionForPastDate(newDueDate)
            }
            .onChange(of: status) { _, newStatus in
                if newStatus == .paid || newStatus == .received {
                    hasPaidDate = true
                } else {
                    hasPaidDate = false
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
        guard !categoryWasManuallySelected, type == .expense else { return }
        let suggestion = CategorySuggestionService.suggestion(
            for: title,
            using: transactions,
            excluding: transaction?.id
        )
        suggestedCategory = suggestion
        category = suggestion ?? .other
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
            transaction.customCategoryID = customCategoryID
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
                customCategoryID: customCategoryID,
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

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            isShowingSaveError = true
        }
    }

    private func completedStatus(for type: TransactionType) -> TransactionStatus {
        type == .income ? .received : .paid
    }

    private func suggestCompletionForPastDate(_ newDueDate: Date) {
        guard transaction == nil,
              status == .pending,
              newDueDate < Calendar.current.startOfDay(for: .now) else {
            return
        }

        paidDate = newDueDate
        hasPaidDate = true
        status = completedStatus(for: type)
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

private enum TransactionFormField: Hashable {
    case title
    case amount
}

private struct TransactionDescriptionSection: View {
    @Binding var title: String
    let focusedField: FocusState<TransactionFormField?>.Binding

    var body: some View {
        Section("Description") {
            HStack(spacing: 12) {
                TransactionFormIcon(systemImage: "text.alignleft", tint: .blue)

                TextField("Description", text: $title)
                    .textInputAutocapitalization(.sentences)
                    .font(.body.weight(.medium))
                    .focused(focusedField, equals: .title)
            }
            .padding(.vertical, 4)
        }
    }
}

private struct TransactionAmountSection: View {
    @Binding var amountText: String
    let focusedField: FocusState<TransactionFormField?>.Binding

    var body: some View {
        Section("Amount") {
            HStack(spacing: 12) {
                TransactionFormIcon(systemImage: "banknote", tint: .green)

                TextField("Amount", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.trailing)
                    .focused(focusedField, equals: .amount)
            }
            .padding(.vertical, 4)
        }
    }
}

private struct TransactionTypeSection: View {
    @Binding var type: TransactionType

    var body: some View {
        Section("Type") {
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
    @Binding var customCategoryID: String?
    let definitions: [CategoryDefinition]
    let suggestedCategory: CategoryKind?
    let onManualSelection: () -> Void

    var body: some View {
        Section("Category") {
            Menu {
                ForEach(options) { option in
                    Button {
                        category = option.legacyKind ?? .other
                        customCategoryID = option.legacyKind == nil ? option.id : nil
                        onManualSelection()
                    } label: {
                        Label(option.name, systemImage: option.systemImage)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    TransactionFormIcon(systemImage: selectedOption.systemImage, tint: selectedOption.tint)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(selectedOption.name)
                            .font(.body.weight(.semibold))

                        if suggestedCategory == category {
                            Label("Suggested category", systemImage: "sparkles")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .contentShape(.rect)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }

    private var options: [CategoryOption] {
        CategoryOption.available(definitions: definitions, locale: locale)
    }

    private var selectedOption: CategoryOption {
        CategoryOption.resolve(id: customCategoryID ?? category.rawValue, definitions: definitions, locale: locale)
    }
}

private struct TransactionFormIcon: View {
    let systemImage: String
    let tint: Color

    var body: some View {
        Image(systemName: systemImage)
            .font(.body.weight(.semibold))
            .foregroundStyle(tint)
            .frame(width: 36, height: 36)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .accessibilityHidden(true)
    }
}

private struct TransactionDatesSection: View {
    @Binding var dueDate: Date
    @Binding var hasPaidDate: Bool
    @Binding var paidDate: Date
    @Binding var status: TransactionStatus
    let onPresentDatePicker: () -> Void

    var body: some View {
        Section("Dates") {
            TransactionDateRow(
                title: "Date",
                date: $dueDate,
                onPresent: onPresentDatePicker
            )

            Picker("Status", selection: $status) {
                ForEach(TransactionStatus.allCases) { transactionStatus in
                    Text(transactionStatus.title).tag(transactionStatus)
                }
            }

            if hasPaidDate {
                TransactionDateRow(
                    title: "Paid or received date",
                    date: $paidDate,
                    onPresent: onPresentDatePicker
                )
            }
        }
    }
}

private struct TransactionDateRow: View {
    let title: LocalizedStringKey
    @Binding var date: Date
    let onPresent: () -> Void
    @State private var isShowingCalendar = false

    var body: some View {
        Button {
            onPresent()
            isShowingCalendar = true
        } label: {
            LabeledContent(title) {
                Text(date, format: .dateTime.day().month().year())
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isShowingCalendar) {
            NavigationStack {
                DatePicker(title, selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .onChange(of: date) {
                        isShowingCalendar = false
                    }
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                isShowingCalendar = false
                            }
                        }
                    }
            }
            .frame(
                minWidth: 320,
                idealWidth: 360,
                minHeight: 440,
                idealHeight: 500
            )
            .presentationSizing(.fitted)
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
