import Foundation

/// Read-only calculation. Projected occurrences never create transactions.
enum PaydayForecast {
    struct Entry: Identifiable {
        let transaction: Transaction
        let date: Date
        let projected: Bool
        var id: String { transaction.id.uuidString + ":" + String(date.timeIntervalSince1970) }
        var amount: Decimal { transaction.amount }
    }

    struct Result {
        let startDate: Date
        let salary: Transaction
        let expenses: [Entry]
        let income: [Entry]
        var expensesTotal: Decimal { expenses.reduce(0) { $0 + $1.amount } }
        var incomeTotal: Decimal { income.reduce(0) { $0 + $1.amount } }
        var net: Decimal { incomeTotal - expensesTotal }
        var projectedIncomeTotal: Decimal { income.filter(\.projected).reduce(0) { $0 + $1.amount } }
        var projectedExpensesTotal: Decimal { expenses.filter(\.projected).reduce(0) { $0 + $1.amount } }
        var projectedCount: Int { (income + expenses).filter(\.projected).count }

    }

    static func salaryCandidates(_ transactions: [Transaction], now: Date = .now, calendar: Calendar = .current) -> [Transaction] {
        transactions.filter {
            !$0.isArchived && $0.status != .cancelled && !$0.isSettled && $0.type == .income
                && calendar.startOfDay(for: $0.dueDate) >= calendar.startOfDay(for: now)
        }.sorted { $0.dueDate == $1.dueDate ? $0.id.uuidString < $1.id.uuidString : $0.dueDate < $1.dueDate }
    }

    static func suggestedSalary(_ candidates: [Transaction]) -> Transaction? {
        candidates.first {
            let title = $0.title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "nb"))
            return title.contains("lønn") || title.contains("lonn") || title.contains("salary")
        }
    }

    static func selectedSalary(selection: String, transactions: [Transaction], now: Date = .now, calendar: Calendar = .current) -> Transaction? {
        guard selection != "none" else { return nil }
        let candidates = salaryCandidates(transactions, now: now, calendar: calendar)
        if let selected = candidates.first(where: { $0.id.uuidString == selection }) { return selected }
        // A synchronized ID may arrive before the matching transaction. Never silently substitute another salary.
        if !selection.isEmpty && !transactions.contains(where: { $0.id.uuidString == selection }) { return nil }
        return suggestedSalary(candidates)
    }

    static func calculate(transactions: [Transaction], salaryID: UUID?, now: Date = .now, calendar: Calendar = .current) -> Result? {
        guard let salary = salaryCandidates(transactions, now: now, calendar: calendar).first(where: { $0.id == salaryID }) else { return nil }
        let end = calendar.startOfDay(for: salary.dueDate)
        let today = calendar.startOfDay(for: now)
        var entries = transactions.filter {
            !$0.isArchived && $0.status != .cancelled && !$0.isSettled
                && calendar.startOfDay(for: $0.dueDate) <= end
                && ($0.type == .expense || calendar.startOfDay(for: $0.dueDate) >= today)
        }.map { Entry(transaction: $0, date: $0.dueDate, projected: false) }

        // An explicit occurrence (including a cancelled/archived one) wins over a projection.
        let groups = Dictionary(grouping: transactions.filter { $0.recurrence != .none || $0.recurrenceSeriesID != nil }, by: seriesKey)
        for group in groups.values {
            let ordered = group.sorted { $0.dueDate < $1.dueDate }
            for (index, source) in ordered.enumerated() where !source.isArchived && source.status != .cancelled {
                let nextExplicit = index + 1 < ordered.count ? calendar.startOfDay(for: ordered[index + 1].dueDate) : nil
                var previous = source.dueDate
                while let next = RecurrenceService.nextDueDate(after: previous, for: source, calendar: calendar), next > previous {
                    let day = calendar.startOfDay(for: next)
                    guard day <= end, nextExplicit.map({ day < $0 }) ?? true else { break }
                    if day >= today {
                        entries.append(Entry(transaction: source, date: next, projected: true))
                    }
                    previous = next
                }
            }
        }
        entries.sort { $0.date == $1.date ? $0.id < $1.id : $0.date < $1.date }
        let expenses = entries.filter { $0.transaction.type == .expense }
        let income = entries.filter {
            $0.transaction.type == .income && $0.transaction.id != salary.id
                && !(salary.recurrence != .none && seriesKey($0.transaction) == seriesKey(salary))
        }
        return Result(startDate: today, salary: salary, expenses: expenses, income: income)
    }

    private static func seriesKey(_ transaction: Transaction) -> String {
        if let id = transaction.recurrenceSeriesID { return id.uuidString }
        // Legacy series use the same template identity as RecurrenceService.
        let fields = [transaction.title, transaction.amount.description, transaction.type.rawValue,
                      transaction.categoryID, transaction.recurrence.rawValue,
                      String(transaction.recurrenceIntervalMonths ?? 1), transaction.notes]
        return fields.map { String($0.utf8.count) + ":" + $0 }.joined()
    }
}
