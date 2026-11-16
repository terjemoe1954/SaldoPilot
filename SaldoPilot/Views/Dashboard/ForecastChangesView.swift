import SwiftData
import SwiftUI

struct ForecastChangesView: View {
    @Environment(\.locale) private var locale
    let current: ForecastChanges.Snapshot
    let transactions: [Transaction]
    let history: ForecastChangeHistory
    @State private var confirmsNewBaseline = false

    private var comparison: ForecastChanges.Comparison? {
        history.baseline.map { ForecastChanges.compare($0, current, transactions: transactions) }
    }
    var body: some View {
        Form {
            if let comparison {
                Section("Change in expected result") {
                    LabeledContent("Saved forecast", value: comparison.before.net.formattedCurrency)
                    LabeledContent("Current forecast", value: comparison.after.net.formattedCurrency)
                    LabeledContent("Change", value: signed(comparison.difference))
                        .fontWeight(.bold)
                        .foregroundStyle(comparison.difference < 0 ? Color.red : Color.primary)
                    LabeledContent("Compared with", value: comparison.before.capturedAt.formatted(.dateTime.day().month().year().hour().minute().locale(locale)))
                    Text("Expected surplus or deficit - not your bank balance.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if comparison.salaryChanged || comparison.startDateChanged {
                    Section("Changed calculation period") {
                        if comparison.salaryChanged {
                            Text("The selected salary or payday changed. This can change which transactions are included.")
                        }
                        if comparison.startDateChanged {
                            Text("The forecast now starts on a different day. This can change which income and recurring occurrences are included.")
                        }
                        LabeledContent("Previous period", value: period(comparison.before))
                        LabeledContent("Current period", value: period(comparison.after))
                    }
                }
                Section("Transactions explaining the change") {
                    if comparison.changes.isEmpty {
                        Text("No changes since the saved forecast. This is the comparison starting point on this device.")
                    } else {
                        ForEach(comparison.changes) { change in
                            if let transaction = transactions.first(where: { $0.id == change.transactionID }) {
                                NavigationLink { TransactionDetailView(transaction: transaction) } label: { row(change) }
                            } else {
                                VStack(alignment: .leading, spacing: 4) {
                                    row(change)
                                    Text("This transaction is no longer available on this device. Its saved amount is retained in the comparison.")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                Section {
                    Text("Each amount shows its effect on the forecast: positive raises the result, negative lowers it. A paid bill leaves the list of unpaid expenses, so the result can rise without adding money to your account.")
                    Text("This explanation uses the calculation directly. It does not guess causes or send your financial data to an AI service.")
                }
            }
            Section {
                Button("Compare from now on") { confirmsNewBaseline = true }
            } footer: {
                Text("The comparison starting point is stored on this device. It stays fixed until you choose to replace it. Transactions and the shared salary choice are unchanged.")
            }
        }
        .navigationTitle("What changed?")
        .confirmationDialog("Use the current forecast as the new comparison starting point?", isPresented: $confirmsNewBaseline, titleVisibility: .visible) {
            Button("Use current forecast") { history.save(current) }
            Button("Cancel", role: .cancel) { }
        }
    }
    private func row(_ change: ForecastChanges.Change) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(change.title).fontWeight(.semibold)
                Spacer()
                Text(signed(change.effect)).fontWeight(.semibold)
            }
            Text(reason(change.reason)).font(.subheadline).foregroundStyle(.secondary)
            if let before = change.before {
                LabeledContent("Previously included", value: before.amount.formattedCurrency)
                    .font(.caption)
            }
            if let after = change.after {
                LabeledContent("Included now", value: after.amount.formattedCurrency)
                    .font(.caption)
            }
            Text((change.after?.date ?? change.before!.date).formatted(.dateTime.day().month(.abbreviated).year().locale(locale)))
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    private func signed(_ amount: Decimal) -> String {
        (amount > 0 ? "+ " : "") + amount.formattedCurrency
    }
    private func period(_ snapshot: ForecastChanges.Snapshot) -> String {
        snapshot.startDate.formatted(.dateTime.day().month().locale(locale)) + " - " + snapshot.payday.formatted(.dateTime.day().month().year().locale(locale))
    }
    private func reason(_ reason: ForecastChanges.Reason) -> LocalizedStringKey {
        switch reason {
        case .included: "Now included in the forecast"
        case .amountChanged: "Amount changed"
        case .dateChanged: "Due date changed"
        case .titleChanged: "Title changed; the amount is unchanged"
        case .received: "Marked received; no longer expected income"
        case .paid: "Marked paid; no longer an unpaid expense"
        case .cancelled: "Cancelled; no longer included"
        case .archived: "Archived; no longer included"
        case .noLongerIncluded: "No longer included in this forecast"
        case .occurrenceRegistered: "Estimated recurrence is now a registered transaction"
        case .typeChanged: "Income or expense type changed"
        }
    }
}
