import Foundation
#if canImport(SaldoPilot)
@testable import SaldoPilot
#endif

@MainActor
enum PaydayForecastVerification {
    struct Failure: Error { let message: String }
    static func run() throws {
        func check(_ condition: Bool, _ message: String) throws {
            if !condition { throw Failure(message: message) }
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Oslo")!
        func date(_ month: Int, _ day: Int) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
        }
        let now = date(11, 16), start = date(11, 1)
        let salary = Transaction(title: "Lønn", amount: 32000, type: .income, dueDate: date(11, 30), category: .income)
        let received = Transaction(title: "Received", amount: 500, type: .income, dueDate: start, paidDate: start, status: .received)
        let paid = Transaction(title: "Paid", amount: 200, type: .expense, dueDate: start, paidDate: start, status: .paid)
        let overdue = Transaction(title: "Overdue", amount: 100, type: .expense, dueDate: date(10, 30))
        let bill = Transaction(title: "Bill", amount: 300, type: .expense, dueDate: date(11, 25))
        let paydayBill = Transaction(title: "Payday bill", amount: 50, type: .expense, dueDate: salary.dueDate)
        let later = Transaction(title: "Later", amount: 999, type: .expense, dueDate: date(12, 1))
        let expected = Transaction(title: "Refund", amount: 75, type: .income, dueDate: date(11, 20))
        let futurePaid = Transaction(title: "Future paid", amount: 900, type: .expense, dueDate: date(11, 25), paidDate: date(11, 25), status: .paid)
        let cancelled = Transaction(title: "Cancelled", amount: 900, type: .expense, dueDate: now, status: .cancelled)
        let archived = Transaction(title: "Archived", amount: 900, type: .expense, dueDate: now, isArchived: true)
        let undated = Transaction(title: "No payment date", amount: 900, type: .expense, dueDate: now, status: .paid)
        let oldPaid = Transaction(title: "Before balance", amount: 900, type: .expense, dueDate: date(10, 1), paidDate: date(10, 1), status: .paid)
        let input = [salary, received, paid, overdue, bill, paydayBill, later, expected, futurePaid, cancelled, archived, undated, oldPaid]
        func calculate(_ items: [Transaction]) -> PaydayForecast.Result? {
            PaydayForecast.calculate(transactions: items, salaryID: salary.id, now: now, calendar: calendar)
        }
        guard let result = calculate(input) else { throw Failure(message: "Missing result") }
        try check(result.startDate == calendar.startOfDay(for: now), "Forecast starts today, without an opening balance")
        try check(result.expensesTotal == 450 && result.net == -375, "Include overdue and payday bills, exclude later and completed payments")
        try check(result.incomeTotal == 75, "Selected salary is not included in expected income")
        try check(Set(result.expenses.map { $0.transaction.id }) == Set([overdue.id, bill.id, paydayBill.id]), "Expense drilldown must exactly match the total")
        try check(result.income.map { $0.transaction.id } == [expected.id], "Income drilldown must exactly match the total")
        expected.amount = 700
        try check(calculate(input)?.net == 250, "Positive surplus")
        expected.amount = 450
        try check(calculate(input)?.net == 0, "Balanced income and expenses")
        expected.amount = 75
        try check(PaydayForecast.calculate(transactions: input, salaryID: nil, now: now, calendar: calendar) == nil, "Missing salary must not be guessed by calculator")
        let overdueIncome = Transaction(title: "Overdue refund", amount: 1000, type: .income, dueDate: date(11, 15))
        try check(calculate(input + [overdueIncome])?.incomeTotal == 75, "Overdue income with unknown receipt date is excluded")
        try check(calculate([salary])?.net == 0, "No other activity gives zero, not the salary amount")
        try check(PaydayForecast.suggestedSalary(PaydayForecast.salaryCandidates(input, now: now, calendar: calendar))?.id == salary.id, "Suggest registered salary, not refund")
        let series = UUID()
        let recurring = Transaction(title: "Monthly", amount: Decimal(string: "1249.50")!, type: .expense, dueDate: date(10, 31), paidDate: date(10, 31), status: .paid, recurrence: .monthly, recurrenceSeriesID: series, recurrenceAnchorDay: 31)
        let projected = calculate([salary, recurring])!
        try check(projected.expenses.count == 1 && projected.expenses[0].projected && calendar.component(.day, from: projected.expenses[0].date) == 30, "Project month-end recurrence without saving")
        let explicit = Transaction(title: "Monthly edited", amount: 1200, type: .expense, dueDate: date(11, 30), recurrence: .monthly, recurrenceSeriesID: series, recurrenceAnchorDay: 31)
        try check(calculate([salary, recurring, explicit])?.expensesTotal == 1200, "Explicit occurrence wins; no double counting")
        explicit.recurrence = .none
        try check(calculate([salary, recurring, explicit])?.expensesTotal == 1200, "Explicit occurrence with recurrence stopped must still win")
        explicit.status = .cancelled
        try check(calculate([salary, recurring, explicit])?.expenses.isEmpty == true, "Cancelled occurrence must not reappear as a projection")
        explicit.status = .paid; explicit.paidDate = now
        try check(calculate([salary, recurring, explicit])?.expenses.isEmpty == true, "Settled occurrence must not be projected again")
        try check(recurring.dueDate == date(10, 31) && recurring.status == .paid && input.count == 13, "Calculation never mutates inputs")
    }
}
