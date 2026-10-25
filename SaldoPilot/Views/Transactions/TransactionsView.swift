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
    @Environment(\.locale) private var locale
    @Query(sort: \Transaction.dueDate) private var transactions: [Transaction]
    @Query(sort: \CategoryDefinition.name) private var categoryDefinitions: [CategoryDefinition]
    @AppStorage(AppSettingsKey.showCompletedStatus) private var showCompletedStatus = true
    @AppStorage(AppSettingsKey.showSettledTransactions) private var showSettledTransactions = true
    @AppStorage(AppSettingsKey.defaultPeriod) private var defaultPeriodRawValue = AppDefaultPeriod.thisMonth.rawValue
    @AppStorage(AppSettingsKey.defaultDateType) private var defaultDateTypeRawValue = AppDefaultDateType.dueDate.rawValue
    @AppStorage(AppSettingsKey.openingBalanceAmount) private var openingBalanceAmountText = ""
    @AppStorage(AppSettingsKey.openingBalanceDate) private var openingBalanceDateTimestamp = Date.now.timeIntervalSince1970

    @State private var selectedFilter: TransactionListFilter = .all
    @State private var advancedFilter = TransactionAdvancedFilter()
    @State private var searchText = ""
    @State private var editingTransaction: Transaction?
    @State private var transactionPendingDeletion: Transaction?
    @State private var isShowingAdvancedFilter = false
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingDeletionError = false
    @State private var isShowingSaveError = false

    private let initialFilter: TransactionListFilter
    private var newTransactionAction: (() -> Void)?

    init(initialFilter: TransactionListFilter = .all) {
        self.initialFilter = initialFilter
        _selectedFilter = State(initialValue: initialFilter)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AvailableAmountBanner(
                    amount: availableAmount,
                    showsCalculationBasis: availableAmount != nil
                )
                TransactionFilterPicker(selectedFilter: $selectedFilter)

                if advancedFilter.hasActiveFilters {
                    TransactionActiveFilterChips(filter: $advancedFilter, definitions: categoryDefinitions)
                }

                TransactionSelectionSummary(
                    income: filteredSummary.income,
                    expenses: filteredSummary.expenses,
                    receivable: filteredSummary.receivable,
                    net: filteredSummary.net,
                    shownCount: filteredTransactions.count,
                    totalCount: activeTransactions.count
                )

                if filteredTransactions.isEmpty {
                    TransactionEmptyState(
                        filter: selectedFilter,
                        showsAddAction: activeTransactions.isEmpty,
                        onAdd: { newTransactionAction?() }
                    )
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
                                if !transaction.isSettled {
                                    Button {
                                        markCompleted(transaction)
                                    } label: {
                                        Label("Mark paid", systemImage: "checkmark.circle")
                                    }
                                    .tint(.green)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    requestDelete(transaction)
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
            .searchable(text: $searchText, prompt: "Search transactions")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        newTransactionAction?()
                    } label: {
                        Label("New transaction", systemImage: "plus")
                    }

                    Button {
                        isShowingAdvancedFilter = true
                    } label: {
                        Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(item: $editingTransaction) { transaction in
                TransactionFormView(transaction: transaction)
            }
            .confirmationDialog(
                "Delete transaction?",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                if shouldAskForRecurringDeletion {
                    Button("Delete only this transaction", role: .destructive) {
                        confirmDelete(scope: .single)
                    }
                    Button("Delete this and future transactions", role: .destructive) {
                        confirmDelete(scope: .thisAndFuture)
                    }
                } else {
                    Button("Delete", role: .destructive) {
                        confirmDelete(scope: .single)
                    }
                }
                Button("Cancel", role: .cancel) {
                    transactionPendingDeletion = nil
                }
            } message: {
                Text(deleteConfirmationMessage)
            }
            .alert("Could not delete transaction", isPresented: $isShowingDeletionError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The deletion was not saved. The transaction has been restored. Check the connection and try again.")
            }
            .alert("Could not save transaction", isPresented: $isShowingSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The changes were not saved. Check the connection and try again.")
            }
            .sheet(isPresented: $isShowingAdvancedFilter) {
                TransactionFilterSheet(filter: $advancedFilter, definitions: categoryDefinitions)
            }
            .onAppear {
                applyDefaultFiltersIfNeeded()
            }
            .onChange(of: initialFilter) { _, newFilter in
                selectedFilter = newFilter
            }
        }
    }

    func onNewTransaction(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.newTransactionAction = action
        return copy
    }

    private var activeTransactions: [Transaction] {
        transactions.filter { !$0.isArchived && $0.status != .cancelled }
    }

    private var filteredTransactions: [Transaction] {
        let nextDueDate = activeTransactions
            .filter { $0.type == .expense && $0.status == .pending && !$0.isCompleted && $0.dueDate >= Calendar.current.startOfDay(for: .now) }
            .map(\.dueDate)
            .min()

        let filteredTransactions = activeTransactions.filter { transaction in
            selectedFilter.includes(transaction, nextDueDate: nextDueDate) &&
            advancedFilter.includes(transaction) &&
            includesSettledTransaction(transaction) &&
            includesSearch(transaction)
        }

        return advancedFilter.sort(filteredTransactions)
    }

    private var filteredSummary: TransactionFilteredSummary {
        let income = filteredTransactions
            .filter { $0.type == .income }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let expenses = filteredTransactions
            .filter { $0.type == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let receivable = filteredTransactions
            .filter {
                $0.type == .income &&
                !$0.isCompleted &&
                $0.status == .pending
            }
            .reduce(Decimal.zero) { $0 + $1.amount }

        return TransactionFilteredSummary(
            income: income,
            expenses: expenses,
            receivable: receivable,
            net: income - expenses
        )
    }

    private func includesSettledTransaction(_ transaction: Transaction) -> Bool {
        guard !showSettledTransactions, selectedFilter != .completed else {
            return true
        }

        return !transaction.isSettled
    }

    private func includesSearch(_ transaction: Transaction) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        return transaction.title.localizedStandardContains(query)
            || transaction.notes.localizedStandardContains(query)
            || categoryOption(for: transaction).name.localizedStandardContains(query)
    }

    private var availableAmount: Decimal? {
        AccountBalanceCalculator.availableBalance(
            openingBalanceText: openingBalanceAmountText,
            openingBalanceDate: Date(timeIntervalSince1970: openingBalanceDateTimestamp),
            transactions: transactions
        )
    }

    private func applyDefaultFiltersIfNeeded() {
        guard !advancedFilter.hasActiveFilters else { return }
        let defaultPeriod = AppDefaultPeriod(rawValue: defaultPeriodRawValue) ?? .thisMonth
        let defaultDateType = AppDefaultDateType(rawValue: defaultDateTypeRawValue) ?? .dueDate
        advancedFilter.period = TransactionDatePeriod(defaultPeriod: defaultPeriod)
        advancedFilter.dateType = TransactionFilterDateType(rawValue: defaultDateType.rawValue) ?? .dueDate
    }

    private func markCompleted(_ transaction: Transaction) {
        guard !transaction.isSettled else { return }
        complete(transaction)
    }

    private func complete(_ transaction: Transaction) {
        transaction.paidDate = .now
        transaction.isCompleted = true
        transaction.status = transaction.type == .income ? .received : .paid
        transaction.markUpdated()
        RecurrenceService.insertNextOccurrenceIfNeeded(after: transaction, in: modelContext)
        saveChanges()
    }

    private func duplicate(_ transaction: Transaction) {
        let copy = Transaction(
            title: "\(transaction.title) copy",
            amount: transaction.amount,
            type: transaction.type,
            dueDate: transaction.dueDate,
            status: .pending,
            category: transaction.category,
            customCategoryID: transaction.customCategoryID,
            recurrence: transaction.recurrence,
            recurrenceIntervalMonths: transaction.recurrenceIntervalMonths,
            notes: transaction.notes
        )
        modelContext.insert(copy)
        saveChanges()
    }

    private func categoryOption(for transaction: Transaction) -> CategoryOption {
        CategoryOption.resolve(id: transaction.categoryID, definitions: categoryDefinitions, locale: locale)
    }

    private func edit(_ transaction: Transaction) {
        editingTransaction = transaction
    }

    private func requestDelete(_ transaction: Transaction) {
        transactionPendingDeletion = transaction
        isShowingDeleteConfirmation = true
    }

    private var shouldAskForRecurringDeletion: Bool {
        guard let transactionPendingDeletion, transactionPendingDeletion.recurrence != .none else {
            return false
        }

        let snapshot = RecurrenceService.SeriesSnapshot(transaction: transactionPendingDeletion)
        return !RecurrenceService.futureOccurrences(matching: snapshot, in: transactions).isEmpty
    }

    private var deleteConfirmationMessage: LocalizedStringKey {
        shouldAskForRecurringDeletion
        ? "Choose whether to delete only this transaction or matching future transactions too."
        : "This transaction will be permanently deleted."
    }

    private func confirmDelete(scope: RecurrenceDeletionScope) {
        guard let transactionPendingDeletion else { return }
        if scope == .thisAndFuture {
            let snapshot = RecurrenceService.SeriesSnapshot(transaction: transactionPendingDeletion)
            let futureOccurrences = RecurrenceService.futureOccurrences(matching: snapshot, in: transactions)
            for futureOccurrence in futureOccurrences {
                modelContext.delete(futureOccurrence)
            }
        }

        modelContext.delete(transactionPendingDeletion)
        self.transactionPendingDeletion = nil
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            isShowingDeletionError = true
        }
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            isShowingSaveError = true
        }
    }
}

private enum RecurrenceDeletionScope {
    case single
    case thisAndFuture
}

private struct TransactionAdvancedFilter: Equatable {
    var period: TransactionDatePeriod = .all
    var dateType: TransactionFilterDateType = .dueDate
    var customStartDate = Calendar.current.startOfDay(for: .now)
    var customEndDate = Date.now
    var status: TransactionFilterStatus = .all
    var type: TransactionFilterType = .all
    var categoryID: String?
    var minimumAmountText = ""
    var maximumAmountText = ""
    var sortOption: TransactionSortOption = .dueDate
    var sortDirection: TransactionSortDirection = .ascending

    var hasActiveFilters: Bool {
        period != .all ||
        status != .all ||
        type != .all ||
        categoryID != nil ||
        parsedMinimumAmount != nil ||
        parsedMaximumAmount != nil ||
        sortOption != .dueDate ||
        sortDirection != .ascending
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

        if let categoryID, transaction.categoryID != categoryID {
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

    func sort(_ transactions: [Transaction]) -> [Transaction] {
        transactions.sorted { first, second in
            let comparison = sortOption.compare(first, second)
            if comparison == .orderedSame {
                return first.dueDate < second.dueDate
            }

            switch sortDirection {
            case .ascending:
                return comparison == .orderedAscending
            case .descending:
                return comparison == .orderedDescending
            }
        }
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
        Decimal.localizedValue(from: value)
    }
}

private enum TransactionSortOption: String, CaseIterable, Identifiable {
    case dueDate
    case paidDate
    case amount
    case title
    case category
    case status

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .dueDate:
            "Due date"
        case .paidDate:
            "Paid date"
        case .amount:
            "Amount"
        case .title:
            "Title"
        case .category:
            "Category"
        case .status:
            "Status"
        }
    }

    func compare(_ first: Transaction, _ second: Transaction) -> ComparisonResult {
        switch self {
        case .dueDate:
            return first.dueDate.compare(second.dueDate)
        case .paidDate:
            return optionalDate(first.paidDate).compare(optionalDate(second.paidDate))
        case .amount:
            return NSDecimalNumber(decimal: first.amount).compare(NSDecimalNumber(decimal: second.amount))
        case .title:
            return first.title.localizedCaseInsensitiveCompare(second.title)
        case .category:
            return String(localized: first.category.title).localizedCaseInsensitiveCompare(String(localized: second.category.title))
        case .status:
            return first.effectiveStatus.rawValue.localizedCaseInsensitiveCompare(second.effectiveStatus.rawValue)
        }
    }

    private func optionalDate(_ date: Date?) -> Date {
        date ?? .distantFuture
    }
}

private enum TransactionSortDirection: String, CaseIterable, Identifiable {
    case ascending
    case descending

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .ascending:
            "Ascending"
        case .descending:
            "Descending"
        }
    }
}

private enum TransactionDatePeriod: String, CaseIterable, Identifiable {
    case all
    case next7Days
    case next30Days
    case thisMonth
    case previousMonth
    case thisYear
    case custom

    init(defaultPeriod: AppDefaultPeriod) {
        switch defaultPeriod {
        case .thisMonth:
            self = .thisMonth
        case .previousMonth:
            self = .previousMonth
        case .thisYear:
            self = .thisYear
        case .custom:
            self = .all
        }
    }

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .all:
            "All"
        case .next7Days:
            "Next 7 days"
        case .next30Days:
            "Next 30 days"
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
        case .next7Days, .next30Days, .thisMonth, .previousMonth, .thisYear, .custom:
            guard let date else { return false }
            return dateInterval.containsHalfOpen(date)
        }
    }

    private var dateInterval: DateInterval {
        let calendar = Calendar.current
        let now = Date.now

        switch self {
        case .all:
            return DateInterval(start: .distantPast, end: .distantFuture)
        case .next7Days:
            return upcomingDateInterval(dayCount: 7, calendar: calendar, now: now)
        case .next30Days:
            return upcomingDateInterval(dayCount: 30, calendar: calendar, now: now)
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

    private func upcomingDateInterval(dayCount: Int, calendar: Calendar, now: Date) -> DateInterval {
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: dayCount, to: start) ?? start
        return DateInterval(start: start, end: end)
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

private struct AvailableAmountBanner: View {
    let amount: Decimal?
    let showsCalculationBasis: Bool

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.semibold))
                        .accessibilityHidden(true)

                    if let amount {
                        Text("Available")
                            .font(.caption.weight(.semibold))

                        Text(amount.formattedCurrency)
                            .font(.subheadline.weight(.bold))
                    } else {
                        Text("Set opening balance in Settings")
                            .font(.caption.weight(.semibold))
                    }
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(tint, in: Capsule())
                .accessibilityElement(children: .combine)

                Spacer(minLength: 0)
            }

            if showsCalculationBasis {
                Text(
                    "Based on opening balance and settled transactions, independent of filters",
                    comment: "Short explanation below the available account balance in the transaction list."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var systemImage: String {
        guard let amount else { return "exclamationmark.circle.fill" }
        return amount < .zero ? "minus.circle.fill" : "checkmark.circle.fill"
    }

    private var tint: Color {
        guard let amount else { return .orange }
        return amount < .zero ? .red : .green
    }
}

private struct TransactionFilteredSummary {
    let income: Decimal
    let expenses: Decimal
    let receivable: Decimal
    let net: Decimal
}

private struct TransactionSelectionSummary: View {
    let income: Decimal
    let expenses: Decimal
    let receivable: Decimal
    let net: Decimal
    let shownCount: Int
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ViewThatFits {
                HStack(spacing: 14) {
                    summaryValues
                }

                VStack(alignment: .leading, spacing: 4) {
                    summaryValues
                }
            }

            Text(
                "Visible: \(shownCount) of \(totalCount)",
                comment: "Summary below transaction filters. The first number is visible transactions and the second is all active transactions."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    @ViewBuilder
    private var summaryValues: some View {
        LabeledContent("Income", value: income.formattedCurrency)
            .foregroundStyle(.green)
        LabeledContent("Expenses", value: expenses.formattedCurrency)
            .foregroundStyle(.red)
        LabeledContent("Receivable", value: receivable.formattedCurrency)
            .foregroundStyle(.orange)
        LabeledContent("Net", value: net.formattedCurrency)
            .foregroundStyle(net < .zero ? .red : .primary)
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
            return transaction.type == .expense && transaction.status == .pending && !transaction.isCompleted && Calendar.current.isDate(transaction.dueDate, inSameDayAs: nextDueDate)
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TransactionListFilter.allCases) { filter in
                    let isSelected = selectedFilter == filter

                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.title)
                            .font(.subheadline.weight(isSelected ? .semibold : .regular))
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 44)
                            .foregroundStyle(
                                isSelected
                                    ? AnyShapeStyle(.background)
                                    : AnyShapeStyle(.primary)
                            )
                            .background(
                                isSelected
                                    ? AnyShapeStyle(.primary)
                                    : AnyShapeStyle(Color.secondary.opacity(0.16)),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal)
        }
        .contentMargins(.vertical, 6, for: .scrollContent)
        .background(.bar)
    }
}

private struct TransactionActiveFilterChips: View {
    @Environment(\.locale) private var locale

    @Binding var filter: TransactionAdvancedFilter
    let definitions: [CategoryDefinition]

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

                if filter.sortOption != .dueDate {
                    TransactionFilterChip(title: filter.sortOption.title)
                }

                if filter.sortDirection != .ascending {
                    TransactionFilterChip(title: filter.sortDirection.title)
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
        guard let categoryID = filter.categoryID else { return nil }
        return CategoryOption.resolve(id: categoryID, definitions: definitions, locale: locale).name
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
    @Environment(\.locale) private var locale

    @Binding var filter: TransactionAdvancedFilter
    let definitions: [CategoryDefinition]

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
                    Picker("Category", selection: $filter.categoryID) {
                        Text("All categories").tag(Optional<String>.none)
                        ForEach(CategoryOption.available(definitions: definitions, locale: locale)) { category in
                            Label(category.name, systemImage: category.systemImage)
                                .tag(Optional(category.id))
                        }
                    }
                }

                Section("Amount") {
                    TextField("From", text: $filter.minimumAmountText)
                        .keyboardType(.decimalPad)
                    TextField("To", text: $filter.maximumAmountText)
                        .keyboardType(.decimalPad)
                }

                Section("Sorting") {
                    Picker("Sort by", selection: $filter.sortOption) {
                        ForEach(TransactionSortOption.allCases) { sortOption in
                            Text(sortOption.title).tag(sortOption)
                        }
                    }

                    Picker("Direction", selection: $filter.sortDirection) {
                        ForEach(TransactionSortDirection.allCases) { direction in
                            Text(direction.title).tag(direction)
                        }
                    }
                    .pickerStyle(.segmented)
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
    @Environment(\.locale) private var locale
    @Query(sort: \CategoryDefinition.name) private var categoryDefinitions: [CategoryDefinition]

    let transaction: Transaction
    let showsCompletedStatus: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            TransactionTypeIcon(type: transaction.type)

            VStack(alignment: .leading, spacing: 6) {
                Text(transaction.title)
                    .font(.headline)

                HStack(spacing: 6) {
                    Label(category.name, systemImage: category.systemImage)
                    Text("Due \(transaction.dueDate, format: .dateTime.day().month().year())")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if showsCompletedStatus {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            TransactionStatusBadge(status: transaction.effectiveStatus)
                            TransactionTypeBadge(type: transaction.type)
                        }

                        if let nextDueDate {
                            Label {
                                HStack(spacing: 3) {
                                    recurrenceSummary
                                    Text("·")
                                    Text("Next:")
                                    Text(nextDueDate, format: .dateTime.day().month().year())
                                }
                            } icon: {
                                Image(systemName: "calendar.badge.clock")
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        } else {
                            Label("One-time", systemImage: "calendar")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer(minLength: 8)

            Text(transaction.amount.formattedCurrency)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private var category: CategoryOption {
        CategoryOption.resolve(id: transaction.categoryID, definitions: categoryDefinitions, locale: locale)
    }

    private var nextDueDate: Date? {
        RecurrenceService.nextDueDate(after: transaction.dueDate, for: transaction)
    }

    private var recurrenceSummary: Text {
        switch transaction.recurrence {
        case .everyNMonths, .custom:
            Text("Every \(transaction.recurrenceIntervalMonths ?? 1) months")
        case .none, .monthly, .quarterly, .halfYearly, .yearly:
            Text(transaction.recurrence.title)
        }
    }
}

private struct TransactionTypeIcon: View {
    let type: TransactionType

    var body: some View {
        Image(systemName: type == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
            .font(.title2)
            .foregroundStyle(.primary)
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
            .foregroundStyle(.primary)
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
    let showsAddAction: Bool
    let onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No transactions", systemImage: "list.bullet.rectangle")
        } description: {
            Text(emptyDescription)
        } actions: {
            if showsAddAction {
                Button(action: onAdd) {
                    Label("New transaction", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
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
    @Query(sort: \CategoryDefinition.name) private var categoryDefinitions: [CategoryDefinition]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale

    let transaction: Transaction

    @State private var isShowingCompletionSheet = false
    @State private var isShowingCompletionConfirmation = false
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
                Label(category.name, systemImage: category.systemImage)
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
                modelContext: modelContext,
                onSaved: {
                    isShowingCompletionConfirmation = true
                }
            )
        }
        .alert(completionConfirmationTitle, isPresented: $isShowingCompletionConfirmation) {
            Button("OK", role: .cancel) {}
        }
    }

    private var category: CategoryOption {
        CategoryOption.resolve(id: transaction.categoryID, definitions: categoryDefinitions, locale: locale)
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

    private var completionConfirmationTitle: LocalizedStringKey {
        transaction.type == .income ? "Income registered" : "Payment registered"
    }
}

private struct RegisterCompletionDateView: View {
    @Environment(\.dismiss) private var dismiss

    let transaction: Transaction
    @Binding var completionDate: Date
    let modelContext: ModelContext
    let onSaved: () -> Void

    @State private var isShowingSaveError = false

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
            .alert("Could not save transaction", isPresented: $isShowingSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The changes were not saved. Check the connection and try again.")
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
        completeRegistration()
    }

    private func completeRegistration() {
        let wasCompleted = transaction.isSettled
        transaction.paidDate = completionDate
        transaction.status = transaction.type == .income ? .received : .paid
        transaction.isCompleted = true
        transaction.markUpdated()

        if !wasCompleted {
            RecurrenceService.insertNextOccurrenceIfNeeded(after: transaction, in: modelContext)
        }

        do {
            try modelContext.save()
            dismiss()
            onSaved()
        } catch {
            modelContext.rollback()
            isShowingSaveError = true
        }
    }
}

private extension TransactionDatePeriod {
    func includes(_ date: Date?, customStartDate: Date, customEndDate: Date) -> Bool {
        guard self == .custom else { return includes(date) }
        guard let date else { return false }

        let calendar = Calendar.current
        let firstDay = calendar.startOfDay(for: min(customStartDate, customEndDate))
        let lastDay = calendar.startOfDay(for: max(customStartDate, customEndDate))
        let upperBound = calendar.date(byAdding: .day, value: 1, to: lastDay) ?? lastDay
        let lowerBound = firstDay
        return DateInterval(start: lowerBound, end: upperBound).containsHalfOpen(date)
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
