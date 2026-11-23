import SwiftData
import SwiftUI

struct PaydayForecastCard: View {
    @Environment(\.locale) private var locale
    @Query(sort: \Transaction.dueDate) private var transactions: [Transaction]
    @Environment(ForecastSalarySelection.self) private var salarySelection
    @State private var showingDetails = false

    private var result: PaydayForecast.Result? {
        let salary = PaydayForecast.selectedSalary(selection: salarySelection.value, transactions: transactions)
        return PaydayForecast.calculate(transactions: transactions, salaryID: salary?.id)
    }

    var body: some View {
        Button { showingDetails = true } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Until next salary or pension", systemImage: "calendar.badge.clock").font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right").accessibilityHidden(true)
                }
                if let result {
                    Text(result.salary.title).font(.subheadline.weight(.medium))
                    Text(result.net.formattedCurrency)
                        .font(.title2.bold())
                        .foregroundStyle(result.net < 0 ? Color.red : Color.green)
                    Text(result.net < 0 ? LocalizedStringKey("Expected deficit") : LocalizedStringKey("Expected surplus"))
                        .font(.subheadline).foregroundStyle(.secondary)
                    LabeledContent("Next salary or pension", value: result.salary.dueDate.formatted(.dateTime.day().month(.abbreviated).year().locale(locale)))
                        .font(.subheadline)
                    LabeledContent("Other unpaid income through payday", value: result.incomeTotal.formattedCurrency)
                        .font(.caption)
                    LabeledContent("Unpaid bills through payday", value: "− " + result.expensesTotal.formattedCurrency)
                        .font(.caption)
                    Text("The selected payout itself is not included. Paid transactions are excluded; overdue bills are included.")
                        .font(.caption).foregroundStyle(.secondary)
                    if result.projectedCount > 0 {
                        Text("Includes \(result.projectedCount) estimated recurring occurrences. Open to check the estimates.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if result.net < 0 {
                        Label("Expected expenses exceed expected income in this period.", systemImage: "exclamationmark.triangle")
                            .font(.subheadline).foregroundStyle(.red)
                    }
                } else {
                    Text("Select your next salary or pension to see expected income minus expenses.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Text("Expected surplus or deficit - not your bank balance.").font(.caption).foregroundStyle(.secondary)
                Text("See calculation and included transactions").font(.caption).foregroundStyle(.blue)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 20))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetails) { PaydayForecastView() }
    }
}

struct PaydayForecastView: View {
    @State private var changeHistory = ForecastChangeHistory.live()
    @State private var editingPayday: Transaction?
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Transaction.dueDate) private var transactions: [Transaction]
    @Environment(ForecastSalarySelection.self) private var salarySelection
    private var candidates: [Transaction] { PaydayForecast.salaryCandidates(transactions) }
    private var selectedSalary: Transaction? {
        PaydayForecast.selectedSalary(selection: salarySelection.value, transactions: transactions)
    }
    private var result: PaydayForecast.Result? {
        PaydayForecast.calculate(transactions: transactions, salaryID: selectedSalary?.id)
    }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Next salary or pension", selection: Binding(get: { selectedSalary?.id.uuidString ?? "none" }, set: { salarySelection.select($0) })) {
                        Text("Select income transaction").tag("none")
                        ForEach(candidates, id: \.id) { item in
                            Text(item.title + " · " + item.dueDate.formatted(.dateTime.day().month(.abbreviated).year().locale(locale)) + " · " + item.amount.formattedCurrency)
                                .tag(item.id.uuidString)
                        }
                    }
                    if let salary = selectedSalary {
                        LabeledContent("Selected payout", value: salary.title)
                        LabeledContent("Payout date") {
                            Text(salary.dueDate, format: .dateTime.day().month(.abbreviated).year().locale(locale))
                        }
                        Button { editingPayday = salary } label: {
                            Label("Change date for this payout", systemImage: "calendar.badge.clock")
                        }
                    }
                } header: {
                    Text("Calculation basis")
                } footer: {
                    Text("The forecast is expected income minus unpaid expenses, without an opening balance. It is not your bank balance. Your salary selection syncs through iCloud across devices using the same Apple Account.")
                }

                if salarySelection.accountChanged {
                    Section {
                        Text("Your iCloud account changed. Select a salary again to share this choice with the current account. Previous local choices are preserved.")
                    }
                } else if salarySelection.cloudUnavailable {
                    Section {
                        Text("The salary choice is saved on this device. iCloud could not synchronize the setting yet; the app will retry when active.")
                    }
                }
                if selectedSalary == nil, UUID(uuidString: salarySelection.value) != nil,
                   !transactions.contains(where: { $0.id.uuidString == salarySelection.value }) {
                    Section {
                        Text("Waiting for the selected salary transaction to sync. No other salary is substituted automatically.")
                    }
                }

                Section("How to read the forecast") {
                    Text("We calculate other unpaid income minus unpaid bills from today through the selected payout date. The selected salary or pension itself is excluded, as are completed payments. Overdue unpaid bills are included.")
                    Text("Example: no other unpaid income and 5,000 kr in unpaid bills gives −5,000 kr. This means bills exceed other expected income by 5,000 kr before the payout; it does not mean your bank account is overdrawn.")
                    Text("The monthly overview covers the selected period. This forecast covers a different period and includes estimates from recurring schedules, so the totals can differ.")
                    Text("If December is paid on the 10th instead of the 20th, change the date for that payout above. The normal recurrence day and other saved occurrences are kept. The updated date syncs with the transaction.")
                }
                if let result {
                    Section("Forecast") {
                        LabeledContent("From today", value: result.startDate.formatted(.dateTime.day().month(.abbreviated).year().locale(locale)))
                        LabeledContent("Through payout date", value: result.salary.dueDate.formatted(.dateTime.day().month(.abbreviated).year().locale(locale)))
                        LabeledContent("Other unpaid income through payday", value: result.incomeTotal.formattedCurrency)
                        LabeledContent("Unpaid expenses including overdue bills", value: "− " + result.expensesTotal.formattedCurrency)
                        LabeledContent { Text(result.net.formattedCurrency) } label: {
                            Text(result.net < 0 ? LocalizedStringKey("Expected deficit") : LocalizedStringKey("Expected surplus"))
                        }
                            .fontWeight(.bold)
                            .foregroundStyle(result.net < 0 ? Color.red : Color.green)
                        if result.net < 0 {
                            Label("Expected expenses exceed expected income in this period.", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                        }
                        Text("Expected surplus or deficit - not your bank balance.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    if result.projectedCount > 0 {
                        Section("Estimated recurring occurrences") {
                            LabeledContent("Estimated occurrences", value: String(result.projectedCount))
                            LabeledContent("Estimated recurring income", value: result.projectedIncomeTotal.formattedCurrency)
                            LabeledContent("Estimated recurring bills", value: result.projectedExpensesTotal.formattedCurrency)
                            Text("These estimates are already included in the totals above. They are not extra saved transactions. Check the dated rows below if an amount seems too high.")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    Section("What changed?") {
                        NavigationLink {
                            ForecastChangesView(current: ForecastChanges.Snapshot(result: result), transactions: transactions, history: changeHistory)
                        } label: {
                            Label("See why the forecast changed", systemImage: "arrow.triangle.2.circlepath")
                        }
                        Text("Compared with a saved forecast on this device. Open to see the amounts and transactions explaining the difference.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Section {
                        NavigationLink { TransactionDetailView(transaction: result.salary) } label: {
                            VStack(alignment: .leading) {
                                Text(result.salary.title)
                                Text(result.salary.dueDate.formatted(.dateTime.day().month(.abbreviated).year().locale(locale)) + " · " + result.salary.amount.formattedCurrency)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: { Text("Selected salary") } footer: {
                        Text("The period runs from today through payday. The selected salary and completed payments are excluded. Overdue unpaid bills are included. Expected income is not guaranteed. Dashboard period filters do not affect this calculation.")
                    }
                    Section("Bills included in forecast") {
                        if result.expenses.isEmpty { Text("No unpaid bills in this period") }
                        ForEach(result.expenses) { entry in entryLink(entry) }
                    }
                    Section("Expected income included") {
                        if result.income.isEmpty { Text("No expected income before salary in this period") }
                        ForEach(result.income) { entry in entryLink(entry) }
                    }
                    Section {
                        Text("Recurring occurrences are estimated from registered schedules. Estimated rows open the original transaction and do not create or save new transactions. Unregistered daily spending and bank activity are not included.")
                    }
                } else {
                    Section {
                        if selectedSalary == nil {
                            Text("Select a pending income transaction as your next salary. If it is missing, register it first. No salary date is guessed.")
                        }
                    }
                }
            }
            .sheet(item: $editingPayday) { PaydayDateSheet(transaction: $0) }
            .onAppear { saveFirstComparison() }
            .onChange(of: selectedSalary?.id) { _, _ in saveFirstComparison() }
            .navigationTitle("Until next salary or pension")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func saveFirstComparison() {
        if let result { changeHistory.ensureBaseline(ForecastChanges.Snapshot(result: result)) }
    }

    private func entryLink(_ entry: PaydayForecast.Entry) -> some View {
        NavigationLink { TransactionDetailView(transaction: entry.transaction) } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(entry.transaction.title)
                    Spacer()
                    Text(entry.amount.formattedCurrency)
                }
                Text(entry.date.formatted(.dateTime.day().month(.abbreviated).year().locale(locale))).font(.subheadline).foregroundStyle(.secondary)
                if entry.projected {
                    Label("Estimated recurrence - opens original", systemImage: "repeat")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}
