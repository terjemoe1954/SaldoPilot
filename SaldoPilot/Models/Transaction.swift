//
//  Transaction.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import Foundation
import SwiftData

typealias Transaction = SaldoPilotSchemaV3.Transaction

extension SaldoPilotSchemaV3 {
@Model
final class Transaction {
    var id: UUID = UUID()
    var title: String = ""
    var amount: Decimal = Decimal.zero
    var type: TransactionType = TransactionType.expense
    var dueDate: Date = Date.now
    var paidDate: Date?
    var status: TransactionStatus = TransactionStatus.pending
    var category: CategoryKind = CategoryKind.other
    var recurrence: RecurrenceRule = RecurrenceRule.none
    var recurrenceIntervalMonths: Int?
    var recurrenceSeriesID: UUID?
    var recurrenceAnchorDay: Int?
    var notes: String = ""
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var isCompleted: Bool = false
    var isArchived: Bool = false

    var effectiveStatus: TransactionStatus {
        guard status == .pending, !isCompleted else {
            return status
        }

        return dueDate < Calendar.current.startOfDay(for: .now) ? .overdue : status
    }

    var isSettled: Bool {
        isCompleted || status == .paid || status == .received
    }

    /// Transfers to savings and balance corrections are not ordinary income or spending.
    var isIncludedInOrdinaryCashFlow: Bool {
        guard category != .savings, category != .refund else { return false }
        let normalizedTitle = title.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        ).lowercased()
        return !normalizedTitle.contains("saldojustering")
            && !normalizedTitle.contains("balance adjustment")
    }

    init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        type: TransactionType,
        dueDate: Date,
        paidDate: Date? = nil,
        status: TransactionStatus = .pending,
        category: CategoryKind = .other,
        recurrence: RecurrenceRule = .none,
        recurrenceIntervalMonths: Int? = nil,
        recurrenceSeriesID: UUID? = nil,
        recurrenceAnchorDay: Int? = nil,
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
        self.recurrenceSeriesID = recurrenceSeriesID
        self.recurrenceAnchorDay = recurrenceAnchorDay
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
}
