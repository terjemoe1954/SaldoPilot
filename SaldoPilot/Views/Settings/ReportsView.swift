import SwiftData
import SwiftUI

struct ReportsView: View {
    @Query(sort: \Transaction.dueDate) private var transactions: [Transaction]
    @Query(sort: \CategoryDefinition.name) private var categoryDefinitions: [CategoryDefinition]
    @AppStorage(AppSettingsKey.language) private var languageRawValue = AppLanguage.system.rawValue

    @State private var selectedMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    @State private var selectedReportType = ReportType.transactionList
    @State private var selectedScope = ReportScope.currentSelection
    @State private var selectedDateType = AppDefaultDateType.paidDate
    @State private var includeArchived = false
    @State private var includeCancelled = false
    @State private var reportURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Payment follow-up") {
                NavigationLink {
                    UnpaidBillsView(scope: .allUnpaid)
                } label: {
                    Label("Unpaid bills", systemImage: "checklist")
                }
            }

            Section("Report options") {
                Picker("Report type", selection: $selectedReportType) {
                    ForEach(ReportType.allCases) { reportType in
                        Text(reportType.title)
                            .tag(reportType)
                    }
                }

                Picker("Scope", selection: $selectedScope) {
                    ForEach(ReportScope.allCases) { scope in
                        Text(scope.title)
                            .tag(scope)
                    }
                }

                if selectedReportType.allowsDateTypeSelection {
                    Picker("Date", selection: $selectedDateType) {
                        ForEach(AppDefaultDateType.allCases) { dateType in
                            Text(dateType.title)
                                .tag(dateType)
                        }
                    }
                } else {
                    LabeledContent("Date") {
                        Text(effectiveDateType.title)
                    }
                }

                Picker("Month", selection: $selectedMonth) {
                    ForEach(availableMonths, id: \.self) { month in
                        Text(month, format: .dateTime.month(.wide).year())
                            .tag(month)
                    }
                }

                if selectedScope == .currentSelection {
                    Toggle("Include archived transactions", isOn: $includeArchived)
                    Toggle("Include cancelled transactions", isOn: $includeCancelled)
                } else {
                    Text("All transactions in the selected period are included, including archived and cancelled transactions.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            ReportSummaryView(
                reportType: selectedReportType,
                selectedMonth: selectedMonth,
                transactionCount: reportTransactions.count,
                income: reportTransactions.filter {
                    $0.type == .income && $0.isIncludedInOrdinaryCashFlow
                }.totalAmount,
                expenses: reportTransactions.filter {
                    $0.type == .expense && $0.isIncludedInOrdinaryCashFlow
                }.totalAmount,
                dateType: effectiveDateType,
                scope: selectedScope,
                includeArchived: includeArchived,
                includeCancelled: includeCancelled
            )

            Section {
                Button {
                    createReport()
                } label: {
                    Label("Create PDF report", systemImage: "doc.richtext")
                }
                .disabled(reportTransactions.isEmpty)

                if let reportURL {
                    ShareLink(item: reportURL) {
                        Label("Share PDF", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        ReportPDFService.printReport(at: reportURL, jobName: reportTitle)
                    } label: {
                        Label("Print report", systemImage: "printer")
                    }

                    LabeledContent("PDF file", value: reportURL.lastPathComponent)
                        .font(.footnote)
                }
            } footer: {
                if reportTransactions.isEmpty {
                    Text("There are no transactions for the selected month and filters.")
                } else {
                    Text("Create the report before sharing or printing it. The PDF uses A4 pages and adds page breaks automatically.")
                }
            }
        }
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedMonth) {
            reportURL = nil
        }
        .onChange(of: selectedReportType) {
            reportURL = nil
        }
        .onChange(of: selectedScope) {
            reportURL = nil
        }
        .onChange(of: selectedDateType) {
            reportURL = nil
            if !availableMonths.contains(selectedMonth) {
                selectedMonth = availableMonths.first
                    ?? Calendar.current.dateInterval(of: .month, for: .now)?.start
                    ?? .now
            }
        }
        .onChange(of: includeArchived) {
            reportURL = nil
        }
        .onChange(of: includeCancelled) {
            reportURL = nil
        }
        .alert("Could not create report", isPresented: isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var availableMonths: [Date] {
        let calendar = Calendar.current
        let currentMonth = calendar.dateInterval(of: .month, for: .now)?.start ?? .now
        let transactionMonths: [Date] = transactions.compactMap {
            guard let date = transactionDate(for: $0) else { return nil }
            return calendar.dateInterval(of: .month, for: date)?.start
        }
        return Array(Set(transactionMonths + [currentMonth])).sorted(by: >)
    }

    private var reportTransactions: [Transaction] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: selectedMonth) else {
            return []
        }

        return transactions.filter { transaction in
            guard let date = transactionDate(for: transaction) else { return false }
            let hasReportableStatus = effectiveDateType == .dueDate
                || transaction.effectiveStatus == .paid
                || transaction.effectiveStatus == .received

            let matchesReportType: Bool
            switch selectedReportType {
            case .periodOverview, .transactionList:
                matchesReportType = true
            case .overdueAndUpcoming:
                matchesReportType = transaction.type == .expense
                    && !transaction.isSettled
                    && (transaction.effectiveStatus == .overdue || transaction.status == .pending)
            case .paymentHistory:
                matchesReportType = transaction.isSettled
            }

            let includesArchived = selectedScope == .allTransactions || includeArchived
            let includesCancelled = selectedScope == .allTransactions || includeCancelled

            return interval.containsHalfOpen(date)
                && matchesReportType
                && (hasReportableStatus || (includesCancelled && transaction.status == .cancelled))
                && (includesArchived || !transaction.isArchived)
                && (includesCancelled || transaction.status != .cancelled)
        }
    }

    private func transactionDate(for transaction: Transaction) -> Date? {
        switch effectiveDateType {
        case .dueDate:
            transaction.dueDate
        case .paidDate:
            transaction.paidDate
        }
    }

    private var effectiveDateType: AppDefaultDateType {
        selectedReportType.fixedDateType ?? selectedDateType
    }

    private var selectedLanguage: AppLanguage {
        let language = AppLanguage(rawValue: languageRawValue) ?? .system
        guard language == .system else { return language }

        let identifier = Locale.autoupdatingCurrent.identifier.lowercased()
        if identifier.hasPrefix("th") {
            return .thai
        }
        if identifier.hasPrefix("nb") || identifier.hasPrefix("nn") || identifier.hasPrefix("no") {
            return .norwegian
        }
        return .english
    }

    private var reportTitle: String {
        selectedReportType.title(for: selectedLanguage)
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    @MainActor
    private func createReport() {
        let reportItems = reportTransactions.compactMap { transaction in
            transactionDate(for: transaction).map {
                ReportTransaction(
                    transaction: transaction,
                    transactionDate: $0,
                    categoryName: CategoryOption.resolve(id: transaction.categoryID, definitions: categoryDefinitions, locale: selectedLanguage.locale).name
                )
            }
        }

        do {
            reportURL = try ReportPDFService.makeMonthlyReport(
                transactions: reportItems,
                monthStart: selectedMonth,
                locale: selectedLanguage.locale,
                dateType: effectiveDateType,
                reportTitle: reportTitle,
                selectionDescription: reportSelectionDescription
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var reportSelectionDescription: String {
        switch (selectedLanguage, selectedScope) {
        case (.norwegian, .currentSelection):
            "Omfang: Gjeldende utvalg · Arkiverte: \(includeArchived ? "Ja" : "Nei") · Kansellerte: \(includeCancelled ? "Ja" : "Nei")"
        case (.norwegian, .allTransactions):
            "Omfang: Alle poster i perioden · Arkiverte og kansellerte inkludert"
        case (.thai, .currentSelection):
            "ขอบเขต: รายการที่เลือก · เก็บถาวร: \(includeArchived ? "ใช่" : "ไม่") · ยกเลิก: \(includeCancelled ? "ใช่" : "ไม่")"
        case (.thai, .allTransactions):
            "ขอบเขต: รายการทั้งหมดในช่วงเวลา · รวมรายการเก็บถาวรและยกเลิก"
        case (_, .currentSelection):
            "Scope: Current selection · Archived: \(includeArchived ? "Yes" : "No") · Cancelled: \(includeCancelled ? "Yes" : "No")"
        case (_, .allTransactions):
            "Scope: All transactions in period · Archived and cancelled included"
        }
    }
}

private enum ReportType: String, CaseIterable, Identifiable {
    case periodOverview
    case transactionList
    case overdueAndUpcoming
    case paymentHistory

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .periodOverview: "Period overview"
        case .transactionList: "Transaction list"
        case .overdueAndUpcoming: "Overdue and upcoming"
        case .paymentHistory: "Payment history"
        }
    }

    var fixedDateType: AppDefaultDateType? {
        switch self {
        case .periodOverview, .transactionList: nil
        case .overdueAndUpcoming: .dueDate
        case .paymentHistory: .paidDate
        }
    }

    var allowsDateTypeSelection: Bool { fixedDateType == nil }

    func title(for language: AppLanguage) -> String {
        switch (language, self) {
        case (.norwegian, .periodOverview): "SaldoPilot Periodeoversikt"
        case (.norwegian, .transactionList): "SaldoPilot Bilagsliste"
        case (.norwegian, .overdueAndUpcoming): "SaldoPilot Forfalte og kommende poster"
        case (.norwegian, .paymentHistory): "SaldoPilot Betalingshistorikk"
        case (.thai, .periodOverview): "ภาพรวมช่วงเวลา SaldoPilot"
        case (.thai, .transactionList): "รายการธุรกรรม SaldoPilot"
        case (.thai, .overdueAndUpcoming): "รายการเกินกำหนดและที่กำลังจะมาถึง SaldoPilot"
        case (.thai, .paymentHistory): "ประวัติการชำระเงิน SaldoPilot"
        case (_, .periodOverview): "SaldoPilot Period Overview"
        case (_, .transactionList): "SaldoPilot Transaction List"
        case (_, .overdueAndUpcoming): "SaldoPilot Overdue and Upcoming Transactions"
        case (_, .paymentHistory): "SaldoPilot Payment History"
        }
    }
}

private enum ReportScope: String, CaseIterable, Identifiable {
    case currentSelection
    case allTransactions

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .currentSelection: "Current selection"
        case .allTransactions: "All transactions in period"
        }
    }
}

private struct ReportSummaryView: View {
    let reportType: ReportType
    let selectedMonth: Date
    let transactionCount: Int
    let income: Decimal
    let expenses: Decimal
    let dateType: AppDefaultDateType
    let scope: ReportScope
    let includeArchived: Bool
    let includeCancelled: Bool

    var body: some View {
        Section("Preview") {
            LabeledContent("Report type") {
                Text(reportType.title)
            }
            LabeledContent("Period") {
                Text(selectedMonth, format: .dateTime.month(.wide).year())
            }
            LabeledContent("Date") {
                Text(dateType.title)
            }
            LabeledContent("Scope") {
                Text(scope.title)
            }
            if scope == .currentSelection {
                LabeledContent("Include archived transactions", value: includeArchived ? String(localized: "Yes") : String(localized: "No"))
                LabeledContent("Include cancelled transactions", value: includeCancelled ? String(localized: "Yes") : String(localized: "No"))
            }
            LabeledContent("Transactions", value: transactionCount.formatted())
            LabeledContent(incomeTitle, value: income.formattedCurrency)
            LabeledContent(expensesTitle, value: expenses.formattedCurrency)
            LabeledContent(netTitle, value: (income - expenses).formattedCurrency)
        }
    }

    private var incomeTitle: LocalizedStringResource {
        dateType == .paidDate ? "Income received" : "Income"
    }

    private var expensesTitle: LocalizedStringResource {
        dateType == .paidDate ? "Expenses paid" : "Expenses"
    }

    private var netTitle: LocalizedStringResource {
        dateType == .paidDate ? "Settled net" : "Net"
    }
}

private extension Array where Element == Transaction {
    var totalAmount: Decimal {
        reduce(.zero) { $0 + $1.amount }
    }
}

enum UnpaidBillsScope {
    case allUnpaid
    case overdueOnly
}

struct UnpaidBillsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Query(sort: \Transaction.dueDate) private var transactions: [Transaction]
    @Query(sort: \CategoryDefinition.name) private var categoryDefinitions: [CategoryDefinition]

    @State private var isShowingSaveError = false
    @State private var isShowingPrintError = false

    let scope: UnpaidBillsScope

    var body: some View {
        List {
            Section {
                LabeledContent("Bills", value: unpaidBills.count.formatted())
                LabeledContent("Total", value: totalAmount.formattedCurrency)
            } header: {
                Text(scope == .overdueOnly ? "Overdue at startup" : "Unpaid bills")
            } footer: {
                if scope == .overdueOnly {
                    Text("The oldest overdue bill is shown first.")
                } else {
                    Text("All unpaid bills are sorted by due date, with the oldest first.")
                }
            }

            if unpaidBills.isEmpty {
                ContentUnavailableView(
                    "No unpaid bills",
                    systemImage: "checkmark.circle",
                    description: Text("Everything in this list has been paid.")
                )
            } else {
                if !overdueBills.isEmpty {
                    Section {
                        Button {
                            printOverdueChecklist()
                        } label: {
                            Label("Print overdue checklist", systemImage: "printer")
                        }
                    } header: {
                        Text("Printable checklist")
                    } footer: {
                        Text("The printed checkboxes are for use on paper and do not change transactions in SaldoPilot.")
                    }
                }

                Section("Bills by due date") {
                    ForEach(unpaidBills, id: \.id) { transaction in
                        UnpaidBillRow(
                            title: transaction.title,
                            category: CategoryOption.resolve(id: transaction.categoryID, definitions: categoryDefinitions, locale: locale).name,
                            dueDate: transaction.dueDate,
                            amount: transaction.amount,
                            isOverdue: transaction.effectiveStatus == .overdue,
                            onMarkPaid: { markPaid(transaction) }
                        )
                    }
                }
            }
        }
        .navigationTitle(scope == .overdueOnly ? "Overdue bills" : "Unpaid bills")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Could not save payment", isPresented: $isShowingSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The bill was not marked as paid. Check the connection and try again.")
        }
        .alert("Could not create checklist", isPresented: $isShowingPrintError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The printable checklist could not be created. Please try again.")
        }
    }

    private var unpaidBills: [Transaction] {
        let today = Calendar.current.startOfDay(for: .now)
        return transactions
            .filter { transaction in
                let isUnpaidBill = transaction.type == .expense
                    && transaction.status == .pending
                    && !transaction.isCompleted
                    && !transaction.isArchived
                guard isUnpaidBill else { return false }
                return scope == .allUnpaid || transaction.dueDate < today
            }
            .sorted { $0.dueDate < $1.dueDate }
    }

    private var totalAmount: Decimal {
        unpaidBills.reduce(.zero) { $0 + $1.amount }
    }

    private var overdueBills: [Transaction] {
        let today = Calendar.current.startOfDay(for: .now)
        return unpaidBills.filter { $0.dueDate < today }
    }

    @MainActor
    private func printOverdueChecklist() {
        let reportTransactions = overdueBills.map { transaction in
            ReportTransaction(
                transaction: transaction,
                transactionDate: transaction.dueDate,
                categoryName: CategoryOption.resolve(
                    id: transaction.categoryID,
                    definitions: categoryDefinitions,
                    locale: locale
                ).name
            )
        }

        do {
            let url = try ReportPDFService.makeOverdueChecklist(
                transactions: reportTransactions,
                locale: locale
            )
            ReportPDFService.printReport(at: url, jobName: String(localized: "Overdue checklist"))
        } catch {
            isShowingPrintError = true
        }
    }

    private func markPaid(_ transaction: Transaction) {
        transaction.paidDate = transaction.dueDate
        transaction.status = .paid
        transaction.isCompleted = true
        transaction.markUpdated()
        RecurrenceService.insertNextOccurrenceIfNeeded(after: transaction, in: modelContext)

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            isShowingSaveError = true
        }
    }
}

private struct UnpaidBillRow: View {
    let title: String
    let category: String
    let dueDate: Date
    let amount: Decimal
    let isOverdue: Bool
    let onMarkPaid: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Button(action: onMarkPaid) {
                Image(systemName: "square")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark paid")

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))

                Text(category)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label {
                    Text(dueDate, format: .dateTime.day().month().year())
                } icon: {
                    Image(systemName: isOverdue ? "exclamationmark.triangle.fill" : "calendar")
                }
                .font(.caption)
                .foregroundStyle(isOverdue ? .red : .secondary)
            }

            Spacer(minLength: 8)

            Text(amount.formattedCurrency)
                .font(.body.weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    NavigationStack {
        ReportsView()
    }
}
