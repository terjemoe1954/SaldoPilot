//
//  Transaction.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import Foundation
import SwiftData

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var title: String
    var amount: Decimal
    var type: TransactionType
    var dueDate: Date
    var paidDate: Date?
    var status: TransactionStatus
    var category: Category?
    var recurrence: RecurrenceRule
    var recurrenceIntervalMonths: Int?
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var isCompleted: Bool
    var isArchived: Bool

    var effectiveStatus: TransactionStatus {
        guard status == .pending, !isCompleted else {
            return status
        }

        return dueDate < Calendar.current.startOfDay(for: .now) ? .overdue : status
    }

    init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        type: TransactionType,
        dueDate: Date,
        paidDate: Date? = nil,
        status: TransactionStatus = .pending,
        category: Category? = nil,
        recurrence: RecurrenceRule = .none,
        recurrenceIntervalMonths: Int? = nil,
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isCompleted: Bool = false,
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.type = type
        self.dueDate = dueDate
        self.paidDate = paidDate
        self.status = status
        self.category = category
        self.recurrence = recurrence
        self.recurrenceIntervalMonths = recurrenceIntervalMonths
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isCompleted = isCompleted
        self.isArchived = isArchived
    }

    func markUpdated(at date: Date = .now) {
        updatedAt = date
    }
}
