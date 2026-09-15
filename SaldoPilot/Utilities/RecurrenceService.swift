//
//  RecurrenceService.swift
//  SaldoPilot
//
//  Created by Terje Moe on 14/09/2026.
//

import Foundation
import SwiftData

enum RecurrenceService {
    static func nextDueDate(
        after date: Date,
        for transaction: Transaction,
        calendar: Calendar = .current
    ) -> Date? {
        guard transaction.recurrence != .none else {
            return nil
        }

        return calendar.date(
            byAdding: .month,
            value: monthInterval(for: transaction),
            to: date
        )
    }

    static func insertNextOccurrenceIfNeeded(
        after transaction: Transaction,
        in modelContext: ModelContext,
        calendar: Calendar = .current
    ) {
        guard let nextDueDate = nextDueDate(after: transaction.dueDate, for: transaction, calendar: calendar) else {
            return
        }

        let nextTransaction = Transaction(
            title: transaction.title,
            amount: transaction.amount,
            type: transaction.type,
            dueDate: nextDueDate,
            status: .pending,
            category: transaction.category,
            recurrence: transaction.recurrence,
            recurrenceIntervalMonths: transaction.recurrenceIntervalMonths,
            notes: transaction.notes
        )

        modelContext.insert(nextTransaction)
    }
    private static func monthInterval(for transaction: Transaction) -> Int {
        switch transaction.recurrence {
        case .none:
            0
        case .monthly:
            1
        case .everyNMonths, .custom:
            max(transaction.recurrenceIntervalMonths ?? 1, 1)
        case .quarterly:
            3
        case .halfYearly:
            6
        case .yearly:
            12
        }
    }
}
