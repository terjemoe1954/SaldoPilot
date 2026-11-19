import SwiftData
import SwiftUI

struct TransactionPaymentSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let transaction: Transaction
    @State private var paymentDate: Date
    @State private var isSaving = false
    @State private var isShowingSaveError = false

    init(transaction: Transaction) {
        self.transaction = transaction
        _paymentDate = State(initialValue: TransactionSettlementService.suggestedDate(for: transaction))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent(transaction.title, value: transaction.amount.formattedCurrency)
                    LabeledContent("Due date") {
                        Text(transaction.dueDate, format: .dateTime.day().month().year())
                    }
                }
                Section {
                    DatePicker(transaction.type == .income ? "Received date" : "Paid date", selection: $paymentDate, displayedComponents: .date)
                } footer: {
                    Text("The due date is kept. Choose the date the payment should be recorded on.")
                }
            }
            .navigationTitle(transaction.isSettled ? "Edit payment date" : transaction.type == .income ? "Mark received" : "Register payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(transaction.isSettled ? "Save" : transaction.type == .income ? "Mark received" : "Mark paid") { save() }
                        .disabled(isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .alert("Could not save transaction", isPresented: $isShowingSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The changes were not saved. Check the connection and try again.")
            }
        }
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true
        do {
            try TransactionSettlementService.save(transaction, paymentDate: paymentDate, in: modelContext)
            dismiss()
        } catch {
            isSaving = false
            isShowingSaveError = true
        }
    }
}
