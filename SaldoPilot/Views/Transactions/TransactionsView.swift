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
    @AppStorage(AppSettingsKey.showCompletedStatus) private var showCompletedStatus = true
    @AppStorage(AppSettingsKey.defaultDateType) private var defaultDateTypeRawValue = AppDefaultDateType.dueDate.rawValue

    @State private var selectedFilter: TransactionListFilter = .all
    @State private var advancedFilter = TransactionAdvancedFilter()
    @State private var editingTransaction: Transaction?
    @State private var isShowingEditForm = false
    @State private var isShowingAdvancedFilter = false

    private let initialFilter: TransactionListFilter

    init(initialFilter: TransactionListFilter = .all) {
        self.initialFilter = initialFilter
        _selectedFilter = State(initialValue: initialFilter)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TransactionFilterPicker(selectedFilter: $selectedFilter)

                if advancedFilter.hasActiveFilters {
                    TransactionActiveFilterChips(filter: $advancedFilter)
                }

                if filteredTransactions.isEmpty {
                    TransactionEmptyState(filter: selectedFilter)
                } else {
                    List {
                        ForEach(filteredTransactions, id: \.id) { transaction in
                            NavigationLink {
                                TransactionDetailView(transaction: transaction)
                            } label: {
                                TransactionRowView(
                                    transaction: transaction,
                                    showsCompletedStatus: showCompletedStatus
                                )
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAdvancedFilter = true
                    } label: {
                        Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $isShowingEditForm, onDismiss: { editingTransaction = nil }) {
                if let editingTransaction {
                    TransactionFormView(transaction: editingTransaction)
                }
            }
            .sheet(isPresented: $isShowingAdvancedFilter) {
                TransactionFilterSheet(filter: $advancedFilter)
            }
            .onAppear {
                applyDefaultDateTypeIfNeeded()
            }
            .onChange(of: initialFilter) { _, newFilter in
                selectedFilter = newFilter
            }
        }
    }

    private var activeTransactions: [Transaction] {
        transactions.filter { !$0.isArchived && $0.status != .cancelled }
    }

    private var filteredTransactions: [Transaction] {
        let nextDueDate = activeTransactions
            .filter { $0.status == .pending && !$0.isCompleted && $0.dueDate >= Calendar.current.startOfDay(for: .now) }
            .map(\.dueDate)
            .min()

        return activeTransactions.filter { transaction in
            selectedFilter.includes(transaction, nextDueDate: nextDueDate) && advancedFilter.includes(transaction)
        }
    }

    private func applyDefaultDateTypeIfNeeded() {
        guard !advancedFilter.hasActiveFilters else { return }
        let defaultDateType = AppDefaultDateType(rawValue: defaultDateTypeRawValue) ?? .dueDate
        advancedFilter.dateType = TransactionFilterDateType(rawValue: defaultDateType.rawValue) ?? .dueDate
    }

    private func markCompleted(_ transaction: Transaction) {
        let wasCompleted = transaction.isCompleted || transaction.status == .paid || transaction.status == .received
        transaction.paidDate = .now
        transaction.isCompleted = true
        transaction.status = transaction.type == .income ? .received : .paid
        transaction.markUpdated()

        if !wasCompleted {
            RecurrenceService.insertNextOccurrenceIfNeeded(after: transaction, in: modelContext)
        }
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

private struct TransactionAdvancedFilter: Equatable {
    var period: TransactionDatePeriod = .all
    var dateType: TransactionFilterDateType = .dueDate
    var customStartDate = Calendar.current.startOfDay(for: .now)
    var customEndDate = Date.now
    var status: TransactionFilterStatus = .all
    var type: TransactionFilterType = .all
    var category: CategoryKind?
    var minimumAmountText = ""
    var maximumAmountText = ""

    var hasActiveFilters: Bool {
        period != .all ||
        status != .all ||
        type != .all ||
        category != nil ||
        parsedMinimumAmount != nil ||
        parsedMaximumAmount != nil
    }

    var parsedMinimumAmount: Decimal? {
        parseAmount(minimumAmountText)
    }

    var parsedMaximumAmount: Decimal? {
        parseAmount(maximumAmountText)
    }

    func includes(_ transaction: Transaction) -> Bool {
        if !period.includes(date(for: transaction), customStartDate: customStartDate, customEndDate: customEndDate) {
            return false
        }

        if !status.includes(transaction) {
            return false
        }

        if !type.includes(transaction) {
            return false
        }

        if let category, transaction.category != category {
            return false
        }

        if let parsedMinimumAmount, transaction.amount < parsedMinimumAmount {
            return false
        }

        if let parsedMaximumAmount, transaction.amount > parsedMaximumAmount {
            return false
        }

        return true
    }

    mutating func reset() {
        self = TransactionAdvancedFilter()
    }

    private func date(for transaction: Transaction) -> Date? {
        switch dateType {
        case .dueDate:
            transaction.dueDate
        case .paidDate:
            transaction.paidDate
        }
    }

    private func parseAmount(_ value: String) -> Decimal? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return nil }

        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal

        if let number = formatter.number(from: trimmedValue) {
            return number.decimalValue
        }

        let normalizedValue = trimmedValue.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalizedValue, locale: Locale(identifier: "en_US_POSIX"))
    }
}

private enum TransactionDatePeriod: String, CaseIterable, Identifiable {
    case all
    case thisMonth
    case previousMonth
    case thisYear
    case custom

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .all:
            "All"
        case .thisMonth:
            "This month"
        case .previousMonth:
            "Previous month"
        case .thisYear:
            "This year"
        case .custom:
            "Custom period"
        }
    }

    func includes(_ date: Date?) -> Bool {
        switch self {
        case .all:
            return true
        case .thisMonth, .previousMonth, .thisYear, .custom:
            guard let date else { return false }
            return dateInterval.contains(date)
        }
    }

    private var dateInterval: DateInterval {
        let calendar = Calendar.current
        let now = Date.now

        switch self {
        case .all:
            return DateInterval(start: .distantPast, end: .distantFuture)
        case .thisMonth:
            return calendar.dateInterval(of: .month, for: now) ?? DateInterval(start: .distantPast, end: .distantFuture)
        case .previousMonth:
            let currentMonthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonthStart) ?? now
            return calendar.dateInterval(of: .month, for: previousMonth) ?? DateInterval(start: .distantPast, end: .distantFuture)
        case .thisYear:
            return calendar.dateInterval(of: .year, for: now) ?? DateInterval(start: .distantPast, end: .distantFuture)
        case .custom:
            return DateInterval(start: .distantPast, end: .distantFuture)
        }
    }
}

private enum TransactionFilterDateType: String, CaseIterable, Identifiable {
    case dueDate
    case paidDate

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .dueDate:
            "Due date"
        case .paidDate:
            "Paid date"
        }
    }
}

private enum TransactionFilterStatus: String, CaseIterable, Identifiable {
    case all
    case pending
    case overdue
    case paid
    case received

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .all:
            "All"
        case .pending:
            "Pending"
        case .overdue:
            "Overdue"
        case .paid:
            "Paid"
        case .received:
            "Received"
        }
    }

    func includes(_ transaction: Transaction) -> Bool {
        switch self {
        case .all:
            true
        case .pending:
            transaction.effectiveStatus == .pending
        case .overdue:
            transaction.effectiveStatus == .overdue
        case .paid:
            transaction.status == .paid
        case .received:
            transaction.status == .received
        }
    }
}

private enum TransactionFilterType: String, CaseIterable, Identifiable {
    case all
    case income
    case expense

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .all:
            "All"
        case .income:
            "Income"
        case .expense:
            "Expense"
        }
    }

    func includes(_ transaction: Transaction) -> Bool {
        switch self {
        case .all:
            true
        case .income:
            transaction.type == .income
        case .expense:
            transaction.type == .expense
        }
    }
}

enum TransactionListFilter: String, CaseIterable, Identifiable {
    case all
    case overdue
    case nextDue
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
        case .nextDue:
            "Next due"
        case .upcoming:
            "Upcoming"
        case .completed:
            "Paid"
        case .receivable:
            "Receivable"
        }
    }

    func includes(_ transaction: Transaction, nextDueDate: Date? = nil) -> Bool {
        switch self {
        case .all:
            return true
        case .overdue:
            return transaction.effectiveStatus == .overdue
        case .nextDue:
            guard let nextDueDate else { return false }
            return transaction.status == .pending && !transaction.isCompleted && Calendar.current.isDate(transaction.dueDate, inSameDayAs: nextDueDate)
        case .upcoming:
            return transaction.status == .pending && !transaction.isCompleted && !isPastDue(transaction.dueDate)
        case .completed:
            return transaction.isCompleted || transaction.status == .paid || transaction.status == .received
        case .receivable:
            return transaction.type == .income && transaction.status == .pending && !transaction.isCompleted
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

private struct TransactionActiveFilterChips: View {
    @Binding var filter: TransactionAdvancedFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if filter.period != .all {
                    TransactionFilterChip(title: filter.period.title)
                }

                if filter.dateType != .dueDate && filter.period != .all {
                    TransactionFilterChip(title: filter.dateType.title)
                }

                if filter.status != .all {
                    TransactionFilterChip(title: filter.status.title)
                }

                if filter.type != .all {
                    TransactionFilterChip(title: filter.type.title)
                }

                if let categoryTitle {
                    TransactionFilterChip(text: categoryTitle)
                }

                if filter.parsedMinimumAmount != nil {
                    TransactionFilterChip(title: "Minimum")
                }

                if filter.parsedMaximumAmount != nil {
                    TransactionFilterChip(title: "Maximum")
                }

                Button("Reset") {
                    filter.reset()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    private var categoryTitle: String? {
        guard let category = filter.category else { return nil }
        return String(localized: category.title)
    }
}

private struct TransactionFilterChip: View {
    let title: LocalizedStringKey?
    let text: String?

    init(title: LocalizedStringKey) {
        self.title = title
        text = nil
    }

    init(text: String) {
        title = nil
        self.text = text
    }

    var body: some View {
        Group {
            if let title {
                Text(title)
            } else if let text {
                Text(text)
            }
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundStyle(.primary)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }
}

private struct TransactionFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var filter: TransactionAdvancedFilter

    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    Picker("Period", selection: $filter.period) {
                        ForEach(TransactionDatePeriod.allCases) { period in
                            Text(period.title).tag(period)
                        }
                    }

                    Picker("Date type", selection: $filter.dateType) {
                        ForEach(TransactionFilterDateType.allCases) { dateType in
                            Text(dateType.title).tag(dateType)
                        }
                    }

                    if filter.period == .custom {
                        DatePicker("From", selection: $filter.customStartDate, displayedComponents: .date)
                        DatePicker("To", selection: $filter.customEndDate, displayedComponents: .date)
                    }
                }

                Section("Status") {
                    Picker("Status", selection: $filter.status) {
                        ForEach(TransactionFilterStatus.allCases) { status in
                            Text(status.title).tag(status)
                        }
                    }
                }

                Section("Type") {
                    Picker("Type", selection: $filter.type) {
                        ForEach(TransactionFilterType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $filter.category) {
                        Text("All categories").tag(Optional<CategoryKind>.none)
                        ForEach(CategoryKind.allCases) { category in
                            Label(String(localized: category.title), systemImage: category.systemImage)
                                .tag(Optional(category))
                        }
                    }
                }

                Section("Amount") {
                    TextField("From", text: $filter.minimumAmountText)
                        .keyboardType(.decimalPad)
                    TextField("To", text: $filter.maximumAmountText)
                        .keyboardType(.decimalPad)
                }

                Section {
                    Button("Reset filters") {
                        filter.reset()
                    }
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct TransactionRowView: View {
    let transaction: Transaction
    let showsCompletedStatus: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            TransactionTypeIcon(type: transaction.type)

            VStack(alignment: .leading, spacing: 6) {
                Text(transaction.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Label(String(localized: transaction.category.title), systemImage: transaction.category.systemImage)
                    Text("Due \(transaction.dueDate, format: .dateTime.day().month().year())")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

                if showsCompletedStatus {
                    HStack(spacing: 8) {
                        TransactionStatusBadge(status: transaction.effectiveStatus)
                        TransactionTypeBadge(type: transaction.type)
                    }
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
        case .nextDue:
            "Transactions with the next due date will appear here."
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
    @Environment(\.modelContext) private var modelContext

    let transaction: Transaction

    @State private var isShowingCompletionSheet = false
    @State private var completionDate = Date.now

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
                    LabeledContent(completionDateTitle) {
                        Text(paidDate, format: .dateTime.day().month().year())
                    }
                }
            }

            Section {
                Button {
                    completionDate = transaction.paidDate ?? .now
                    isShowingCompletionSheet = true
                } label: {
                    Label(completionActionTitle, systemImage: "calendar.badge.checkmark")
                }
            }

            Section("Category") {
                Label(String(localized: transaction.category.title), systemImage: transaction.category.systemImage)
            }

            if !transaction.notes.isEmpty {
                Section("Notes") {
                    Text(transaction.notes)
                }
            }
        }
        .navigationTitle(transaction.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingCompletionSheet) {
            RegisterCompletionDateView(
                transaction: transaction,
                completionDate: $completionDate,
                modelContext: modelContext
            )
        }
    }

    private var completionDateTitle: LocalizedStringKey {
        transaction.type == .income ? "Received date" : "Paid date"
    }

    private var completionActionTitle: LocalizedStringKey {
        if transaction.paidDate == nil {
            transaction.type == .income ? "Register received date" : "Register paid date"
        } else {
            transaction.type == .income ? "Change received date" : "Change paid date"
        }
    }
}

private struct RegisterCompletionDateView: View {
    @Environment(\.dismiss) private var dismiss

    let transaction: Transaction
    @Binding var completionDate: Date
    let modelContext: ModelContext

    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    DatePicker(completionDateTitle, selection: $completionDate, displayedComponents: .date)
                }

                Section {
                    Button {
                        registerCompletion()
                    } label: {
                        Label(saveButtonTitle, systemImage: "checkmark.circle")
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var navigationTitle: LocalizedStringKey {
        transaction.type == .income ? "Register received" : "Register paid"
    }

    private var completionDateTitle: LocalizedStringKey {
        transaction.type == .income ? "Received date" : "Paid date"
    }

    private var saveButtonTitle: LocalizedStringKey {
        transaction.type == .income ? "Mark as received" : "Mark as paid"
    }

    private func registerCompletion() {
        let wasCompleted = transaction.isCompleted || transaction.status == .paid || transaction.status == .received
        transaction.paidDate = completionDate
        transaction.status = transaction.type == .income ? .received : .paid
        transaction.isCompleted = true
        transaction.markUpdated()

        if !wasCompleted {
            RecurrenceService.insertNextOccurrenceIfNeeded(after: transaction, in: modelContext)
        }

        dismiss()
    }
}

private extension TransactionDatePeriod {
    func includes(_ date: Date?, customStartDate: Date, customEndDate: Date) -> Bool {
        guard self == .custom else { return includes(date) }
        guard let date else { return false }

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: customStartDate)
        let endDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: customEndDate)) ?? customEndDate
        let lowerBound = min(startDate, endDate)
        let upperBound = max(startDate, endDate)
        return DateInterval(start: lowerBound, end: upperBound).contains(date)
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
