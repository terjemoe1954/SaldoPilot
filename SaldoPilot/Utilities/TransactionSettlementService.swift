import Foundation
import SwiftData

@MainActor
enum TransactionSettlementService {
    enum Failure: Error { case unavailable }

    static func suggestedDate(for transaction: Transaction) -> Date {
        transaction.paidDate ?? transaction.dueDate
    }

    static func save(_ transaction: Transaction, paymentDate: Date, in context: ModelContext) throws {
        guard !transaction.isArchived, transaction.status != .cancelled,
              transaction.modelContext === context else { throw Failure.unavailable }
        let wasSettled = transaction.isSettled
        transaction.paidDate = paymentDate
        transaction.isCompleted = true
        transaction.status = transaction.type == .income ? .received : .paid
        transaction.markUpdated()
        do {
            if !wasSettled {
                try RecurrenceService.insertNextOccurrenceIfNeeded(after: transaction, in: context)
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
