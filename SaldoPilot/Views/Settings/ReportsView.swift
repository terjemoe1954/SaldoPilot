import SwiftData
import SwiftUI

struct ReportsView: View {
    @Query(sort: \Transaction.dueDate) private var transactions: [Transaction]
    @AppStorage(AppSettingsKey.language) private var languageRawValue = AppLanguage.system.rawValue

    @State private var selectedMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    @State private var selectedDateType = AppDefaultDateType.paidDate
    @State private var includeArchived = false
    @State private var includeCancelled = false
    @State private var reportURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Report options") {
                Picker("Date", selection: $selectedDateType) {
                    ForEach(AppDefaultDateType.allCases) { dateType in
                        Text(dateType.title)
                            .tag(dateType)
                    }
                }

                Picker("Month", selection: $selectedMonth) {
                    ForEach(availableMonths, id: \.self) { month in
                        Text(month, format: .dateTime.month(.wide).year())
                            .tag(month)
                    }
                }

                Toggle("Include archived transactions", isOn: $includeArchived)
                Toggle("Include cancelled transactions", isOn: $includeCancelled)
            }

            ReportSummaryView(
                transactionCount: reportTransactions.count,
                income: reportTransactions.filter { $0.type == .income }.totalAmount,
                expenses: reportTransactions.filter { $0.type == .expense }.totalAmount,
                dateType: selectedDateType
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
            let hasReportableStatus = selectedDateType == .dueDate
                || transaction.effectiveStatus == .paid
                || transaction.effectiveStatus == .received

            return interval.contains(date)
                && (hasReportableStatus || (includeCancelled && transaction.status == .cancelled))
                && (includeArchived || !transaction.isArchived)
                && (includeCancelled || transaction.status != .cancelled)
        }
    }

    private func transactionDate(for transaction: Transaction) -> Date? {
        switch selectedDateType {
        case .dueDate:
            transaction.dueDate
        case .paidDate:
            transaction.paidDate
        }
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
        switch selectedLanguage {
        case .norwegian:
            "SaldoPilot Bilagsrapport"
        case .thai:
            "รายงานรายการ SaldoPilot"
        case .system, .english:
            "SaldoPilot Transaction Report"
        }
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
                ReportTransaction(transaction: transaction, transactionDate: $0)
            }
        }

        do {
            reportURL = try ReportPDFService.makeMonthlyReport(
                transactions: reportItems,
                monthStart: selectedMonth,
                locale: selectedLanguage.locale,
                dateType: selectedDateType
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct ReportSummaryView: View {
    let transactionCount: Int
    let income: Decimal
    let expenses: Decimal
    let dateType: AppDefaultDateType

    var body: some View {
        Section("Preview") {
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

#Preview {
    NavigationStack {
        ReportsView()
    }
}
