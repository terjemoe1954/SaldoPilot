import SwiftData
import SwiftUI

struct PaydayDateSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let transaction: Transaction
    private let originalDate: Date
    @State private var date: Date
    @State private var saving = false
    @State private var showError = false
    init(transaction: Transaction) {
        self.transaction = transaction
        originalDate = transaction.dueDate
        _date = State(initialValue: transaction.dueDate)
    }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent(transaction.title, value: transaction.amount.formattedCurrency)
                    DatePicker("Payout date", selection: $date, in: Calendar.current.startOfDay(for: .now)..., displayedComponents: .date)
                } footer: {
                    Text("Only this payout date changes. The normal recurrence day and other saved occurrences are kept. No income is marked as received.")
                }
            }
            .navigationTitle("Change payout date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(saving) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !saving else { return }
                        saving = true
                        do {
                            try PaydayDateAdjustment.save(transaction, date: date, expectedDate: originalDate, in: context)
                            dismiss()
                        } catch { saving = false; showError = true }
                    }.disabled(saving)
                }
            }
            .interactiveDismissDisabled(saving)
            .alert("Could not change payout date", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The payout may have changed on another device. No date was saved. Close and reopen the date editor before trying again.")
            }
        }
    }
}
