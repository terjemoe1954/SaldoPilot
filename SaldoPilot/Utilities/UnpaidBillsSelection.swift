import Foundation

enum UnpaidBillsPeriod: String, CaseIterable, Identifiable {
    case thisMonth, custom, allDates
    var id: String { rawValue }
}

@MainActor
enum UnpaidBillsSelection {
    static func interval(period: UnpaidBillsPeriod, start: Date, end: Date, now: Date = .now, calendar: Calendar = .current) -> DateInterval? {
        switch period {
        case .thisMonth: return calendar.dateInterval(of: .month, for: now)
        case .allDates: return nil
        case .custom:
            let firstDay = calendar.startOfDay(for: start)
            let lastDay = calendar.startOfDay(for: end)
            guard firstDay <= lastDay, let exclusiveEnd = calendar.date(byAdding: .day, value: 1, to: lastDay) else { return nil }
            return DateInterval(start: firstDay, end: exclusiveEnd)
        }
    }

    static func bills(from transactions: [Transaction], overdueOnly: Bool, period: UnpaidBillsPeriod = .allDates, start: Date = .now, end: Date = .now, now: Date = .now, calendar: Calendar = .current) -> [Transaction] {
        let selectedInterval = interval(period: period, start: start, end: end, now: now, calendar: calendar)
        if !overdueOnly && period != .allDates && selectedInterval == nil { return [] }
        let today = calendar.startOfDay(for: now)
        return transactions.filter { transaction in
            guard transaction.type == .expense, !transaction.isCompleted, !transaction.isArchived,
                  transaction.status == .pending || transaction.status == .overdue else { return false }
            if overdueOnly { return transaction.dueDate < today }
            guard let selectedInterval else { return true }
            return transaction.dueDate >= selectedInterval.start && transaction.dueDate < selectedInterval.end
        }.sorted {
            if $0.dueDate != $1.dueDate { return $0.dueDate < $1.dueDate }
            return $0.id.uuidString < $1.id.uuidString
        }
    }
}
