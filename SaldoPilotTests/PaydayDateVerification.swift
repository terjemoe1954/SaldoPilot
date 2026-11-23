import Foundation
import SwiftData
import Testing
@testable import SaldoPilot

@MainActor
enum PaydayDateVerification {
    static func run() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Oslo")!
        func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
        }
        let now = date(2026, 11, 23), original = date(2026, 12, 20), early = date(2026, 12, 10)
        let schema = Schema(SaldoPilotSchemaV7.models)
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)])
        let context = container.mainContext
        let id = UUID(), series = UUID()
        let salary = Transaction(id: id, title: "Alderspensjon", amount: 30045, type: .income, dueDate: original, recurrence: .monthly, recurrenceSeriesID: series)
        let january = Transaction(title: "Alderspensjon", amount: 30045, type: .income, dueDate: date(2027, 1, 20), recurrence: .monthly, recurrenceSeriesID: series, recurrenceAnchorDay: 20)
        let before = Transaction(title: "Before payout", amount: 1000, type: .expense, dueDate: date(2026, 12, 5))
        let after = Transaction(title: "After early payout", amount: 2000, type: .expense, dueDate: date(2026, 12, 15))
        let refund = Transaction(title: "Refund", amount: 500, type: .income, dueDate: date(2026, 12, 7))
        let recurring = Transaction(title: "Recurring bill", amount: 250, type: .expense, dueDate: date(2026, 11, 5), paidDate: date(2026, 11, 5), status: .paid, recurrence: .monthly, recurrenceAnchorDay: 5)
        for t in [salary, january, before, after, refund, recurring] { context.insert(t) }
        try context.save()
        let rows = try context.fetch(FetchDescriptor<Transaction>())
        let old = PaydayForecast.calculate(transactions: rows, salaryID: id, now: now, calendar: calendar)!
        #expect(old.expensesTotal == 3250 && old.net == -2750)
        #expect(old.projectedCount == 1 && old.projectedExpensesTotal == 250 && old.projectedIncomeTotal == 0)
        try PaydayDateAdjustment.save(salary, date: early, expectedDate: original, in: context, now: now, calendar: calendar)
        let result = PaydayForecast.calculate(transactions: rows, salaryID: id, now: now, calendar: calendar)!
        #expect(result.expensesTotal == 1250 && result.incomeTotal == 500 && result.net == -750)
        #expect(!result.expenses.contains { $0.transaction.id == after.id })
        #expect(!result.income.contains { $0.transaction.id == salary.id })
        #expect(salary.id == id && salary.amount == 30045 && salary.status == .pending && salary.paidDate == nil)
        #expect(salary.recurrenceAnchorDay == 20 && salary.recurrenceSeriesID == series)
        #expect(january.dueDate == date(2027, 1, 20))
        #expect(RecurrenceService.nextDueDate(after: salary.dueDate, for: salary, calendar: calendar) == date(2027, 1, 20))
        #expect(try context.fetchCount(FetchDescriptor<Transaction>()) == 6)
        // Same selected ID follows the date change; reopening a context retains the new date.
        #expect(PaydayForecast.selectedSalary(selection: id.uuidString, transactions: rows, now: now, calendar: calendar)?.dueDate == early)
        #expect(try ModelContext(container).fetch(FetchDescriptor<Transaction>()).first(where: { $0.id == id })?.dueDate == early)
        // A stale editor and a past date must leave the saved date untouched.
        do {
            try PaydayDateAdjustment.save(salary, date: date(2026, 12, 11), expectedDate: original, in: context, now: now, calendar: calendar)
            Issue.record("Stale editor overwrote the date")
        } catch { #expect(error is PaydayDateAdjustment.Failure) }
        do {
            try PaydayDateAdjustment.save(salary, date: date(2026, 11, 1), expectedDate: early, in: context, now: now, calendar: calendar)
            Issue.record("Past date accepted")
        } catch { #expect(error is PaydayDateAdjustment.Failure) }
        #expect(salary.dueDate == early)
        // A settled payout cannot be changed from a still-open forecast editor.
        salary.status = .received; try context.save()
        do {
            try PaydayDateAdjustment.save(salary, date: date(2026, 12, 11), expectedDate: early, in: context, now: now, calendar: calendar)
            Issue.record("Settled income was changed")
        } catch { #expect(error is PaydayDateAdjustment.Failure) }
        #expect(salary.dueDate == early)
    }
}
