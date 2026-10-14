//
//  RecurrenceService.swift
//  SaldoPilot
//
//  Created by Terje Moe on 14/09/2026.
//

import Foundation
import SwiftData

enum RecurrenceService {
    struct SeriesSnapshot {
        let id: UUID
        let title: String
        let amount: Decimal
        let type: TransactionType
        let dueDate: Date
        let category: CategoryKind
        let recurrence: RecurrenceRule
        let recurrenceIntervalMonths: Int?
        let recurrenceSeriesID: UUID?
        let notes: String

        init(transaction: Transaction) {
            id = transaction.id
            title = transaction.title
            amount = transaction.amount
            type = transaction.type
            dueDate = transaction.dueDate
            category = transaction.category
            recurrence = transaction.recurrence
            recurrenceIntervalMonths = transaction.recurrenceIntervalMonths
            recurrenceSeriesID = transaction.recurrenceSeriesID
            notes = transaction.notes
        }
    }

    static func nextDueDate(
        after date: Date,
        for transaction: Transaction,
        calendar: Calendar = .current
    ) -> Date? {
        guard transaction.recurrence != .none else {
            return nil
        }

        return nextDueDate(
            after: date,
            anchorDay: transaction.recurrenceAnchorDay ?? calendar.component(.day, from: date),
            monthInterval: monthInterval(for: transaction),
            calendar: calendar
        )
    }

    static func nextDueDate(
        after date: Date,
        anchorDay: Int,
        monthInterval: Int,
        calendar: Calendar = .current
    ) -> Date? {
        guard let targetMonth = calendar.date(
            byAdding: .month,
            value: monthInterval,
            to: date
        ), let dayRange = calendar.range(of: .day, in: .month, for: targetMonth) else {
            return nil
        }

        var components = calendar.dateComponents([.era, .year, .month, .hour, .minute, .second, .nanosecond], from: targetMonth)
        components.day = min(max(anchorDay, dayRange.lowerBound), dayRange.upperBound - 1)
        return calendar.date(from: components)
    }

    static func insertNextOccurrenceIfNeeded(
        after transaction: Transaction,
        in modelContext: ModelContext,
        calendar: Calendar = .current
    ) {
        establishSeriesMetadata(for: transaction, in: modelContext, calendar: calendar)
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
            recurrenceSeriesID: transaction.recurrenceSeriesID,
            recurrenceAnchorDay: transaction.recurrenceAnchorDay,
            notes: transaction.notes
        )

        modelContext.insert(nextTransaction)
    }

    static func futureOccurrences(
        matching snapshot: SeriesSnapshot,
        in transactions: [Transaction]
    ) -> [Transaction] {
        guard snapshot.recurrence != .none else { return [] }

        return transactions
            .filter { transaction in
                transaction.id != snapshot.id &&
                transaction.dueDate > snapshot.dueDate &&
                !transaction.isArchived &&
                transaction.status != .cancelled &&
                !transaction.isSettled &&
                (snapshot.recurrenceSeriesID.map { transaction.recurrenceSeriesID == $0 } ?? (
                transaction.title == snapshot.title &&
                transaction.amount == snapshot.amount &&
                transaction.type == snapshot.type &&
                transaction.category == snapshot.category &&
                transaction.recurrence == snapshot.recurrence &&
                transaction.recurrenceIntervalMonths == snapshot.recurrenceIntervalMonths &&
                transaction.notes == snapshot.notes))
            }
            .sorted { $0.dueDate < $1.dueDate }
    }

    static func applyTemplate(
        from transaction: Transaction,
        toFutureOccurrences futureOccurrences: [Transaction]
    ) {
        for futureOccurrence in futureOccurrences {
            futureOccurrence.title = transaction.title
            futureOccurrence.amount = transaction.amount
            futureOccurrence.type = transaction.type
            futureOccurrence.category = transaction.category
            futureOccurrence.recurrence = transaction.recurrence
            futureOccurrence.recurrenceIntervalMonths = transaction.recurrenceIntervalMonths
            futureOccurrence.recurrenceSeriesID = transaction.recurrenceSeriesID
            futureOccurrence.recurrenceAnchorDay = transaction.recurrenceAnchorDay
            futureOccurrence.notes = transaction.notes
            futureOccurrence.markUpdated()
        }
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

    private static func establishSeriesMetadata(
        for transaction: Transaction,
        in modelContext: ModelContext,
        calendar: Calendar
    ) {
        guard transaction.recurrence != .none else { return }

        let candidates = (try? modelContext.fetch(FetchDescriptor<Transaction>()))?
            .filter {
                $0.title == transaction.title &&
                $0.amount == transaction.amount &&
                $0.type == transaction.type &&
                $0.category == transaction.category &&
                $0.recurrence == transaction.recurrence &&
                $0.recurrenceIntervalMonths == transaction.recurrenceIntervalMonths &&
                $0.notes == transaction.notes
            } ?? [transaction]
        let seriesID = transaction.recurrenceSeriesID
            ?? candidates.compactMap(\.recurrenceSeriesID).first
            ?? UUID()
        let anchorDay = transaction.recurrenceAnchorDay
            ?? candidates.compactMap(\.recurrenceAnchorDay).max()
            ?? candidates.map { calendar.component(.day, from: $0.dueDate) }.max()
            ?? calendar.component(.day, from: transaction.dueDate)

        for candidate in candidates {
            candidate.recurrenceSeriesID = seriesID
            candidate.recurrenceAnchorDay = anchorDay
        }
    }
}
