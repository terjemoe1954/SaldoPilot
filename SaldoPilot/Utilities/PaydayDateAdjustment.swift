import Foundation
import SwiftData

@MainActor
enum PaydayDateAdjustment {
    enum Failure: Error { case unavailable, changedWhileEditing }
    static func save(_ transaction: Transaction, date: Date, expectedDate: Date,
                     in context: ModelContext, now: Date = .now, calendar: Calendar = .current) throws {
        guard transaction.modelContext === context, transaction.type == .income,
              !transaction.isSettled, !transaction.isArchived, transaction.status != .cancelled,
              calendar.startOfDay(for: date) >= calendar.startOfDay(for: now) else { throw Failure.unavailable }
        guard transaction.dueDate == expectedDate else { throw Failure.changedWhileEditing }
        if transaction.recurrence != .none && transaction.recurrenceAnchorDay == nil {
            transaction.recurrenceAnchorDay = calendar.component(.day, from: transaction.dueDate)
        }
        transaction.dueDate = date
        transaction.markUpdated()
        do { try context.save() } catch { context.rollback(); throw error }
    }
}
