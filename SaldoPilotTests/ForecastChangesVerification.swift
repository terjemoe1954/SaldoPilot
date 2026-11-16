import Foundation
#if canImport(SaldoPilot)
@testable import SaldoPilot
#endif

@MainActor
enum ForecastChangesVerification {
    struct Failure: Error { let message: String }
    static func run() throws {
        func check(_ condition: Bool, _ message: String) throws { if !condition { throw Failure(message: message) } }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Oslo")!
        func date(_ month: Int, _ day: Int) -> Date { calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))! }
        let now = date(11,16)
        let salary = Transaction(title: "Lønn", amount: 1000, type: .income, dueDate: date(11,30))
        let bill = Transaction(title: "Strøm", amount: 100, type: .expense, dueDate: date(11,25))
        let income = Transaction(title: "Refusjon", amount: 50, type: .income, dueDate: date(11,16))
        let original = [salary,bill,income]
        func snapshot(_ input: [Transaction], at time: Date? = nil) throws -> ForecastChanges.Snapshot {
            guard let result = PaydayForecast.calculate(transactions: input, salaryID: salary.id, now: time ?? now, calendar: calendar) else { throw Failure(message: "Missing forecast") }
            return ForecastChanges.Snapshot(result: result, capturedAt: time ?? now, calendar: calendar)
        }
        let before = try snapshot(original)
        func compare(_ input: [Transaction], at time: Date? = nil) throws -> ForecastChanges.Comparison {
            let result = ForecastChanges.compare(before, try snapshot(input, at: time), transactions: input)
            try check(result.changes.reduce(Decimal.zero) { $0 + $1.effect } == result.difference, "Every explanation must reconcile exactly")
            return result
        }
        bill.amount = 180
        let changedAmount = try compare(original)
        try check(changedAmount.difference == -80 && changedAmount.changes.count == 1 && changedAmount.changes[0].reason == .amountChanged, "Higher bill explains lower result")
        try check(before.net == -50 && before.lines.first { $0.transactionID == bill.id }?.amount == 100, "Snapshot must not retain mutable model references")
        bill.amount = 100; bill.dueDate = date(11,24)
        let changedDate = try compare(original)
        try check(changedDate.difference == 0 && changedDate.changes.count == 1 && changedDate.changes[0].reason == .dateChanged, "Moved explicit transaction stays one change")
        bill.dueDate = date(11,25); bill.status = .paid
        let paid = try compare(original)
        try check(paid.difference == 100 && paid.changes.first?.reason == .paid, "Payment removes unpaid expense without claiming bank income")
        bill.status = .cancelled
        try check(compare(original).changes.first?.reason == .cancelled, "Cancellation explained")
        bill.status = .pending; bill.isArchived = true
        try check(compare(original).changes.first?.reason == .archived, "Archiving explained")
        bill.isArchived = false
        let missing = try compare([salary,income])
        try check(missing.changes.first?.reason == .noLongerIncluded && missing.changes.first?.transactionID == bill.id, "Unavailable records retain saved amount and identity")
        income.status = .received
        let received = try compare(original)
        try check(received.difference == -50 && received.changes.first?.reason == .received, "Received income leaves expected income")
        income.status = .pending
        let extra = Transaction(title: "Extra", amount: 30, type: .expense, dueDate: date(11,20))
        try check(compare(original + [extra]).difference == -30, "Newly included expense explained")
        salary.dueDate = date(11,20)
        let shorter = try compare(original)
        try check(shorter.salaryChanged && shorter.difference == 100, "Changed payday explains changed period")
        salary.dueDate = date(11,30)
        let tomorrow = try compare(original, at: date(11,17))
        try check(tomorrow.startDateChanged && tomorrow.difference == -50, "New day explains expired expected income")
        let series = UUID()
        let template = Transaction(title: "Monthly", amount: 100, type: .expense, dueDate: date(10,31), status: .paid, recurrence: .monthly, recurrenceSeriesID: series, recurrenceAnchorDay: 31)
        let estimated = try snapshot([salary,template])
        let explicit = Transaction(title: "Monthly", amount: 100, type: .expense, dueDate: date(11,30), recurrence: .monthly, recurrenceSeriesID: series, recurrenceAnchorDay: 31)
        let registered = ForecastChanges.compare(estimated, try snapshot([salary,template,explicit]), transactions: [salary,template,explicit])
        try check(registered.difference == 0 && registered.changes.count == 1 && registered.changes[0].reason == .occurrenceRegistered && registered.changes[0].transactionID == explicit.id, "Registered recurrence replaces estimate without a false amount change")
        let encoded = try JSONEncoder().encode(before)
        try check(JSONDecoder().decode(ForecastChanges.Snapshot.self, from: encoded) == before, "Exact decimal/date persistence")
        let suite = "ForecastChangeHistoryTests-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let history = ForecastChangeHistory(defaults: defaults, key: "baseline")
        history.ensureBaseline(before)
        let after = try snapshot([salary,bill,income,extra])
        history.ensureBaseline(after)
        try check(history.baseline == before, "Opening a forecast never moves an existing baseline")
        try check(ForecastChangeHistory(defaults: defaults, key: "baseline").baseline == before, "Baseline survives reopen")
        history.save(after)
        try check(ForecastChangeHistory(defaults: defaults, key: "baseline").baseline == after, "Explicit replacement starts a fresh comparison")
        defaults.set(Data("invalid".utf8), forKey: "baseline")
        try check(ForecastChangeHistory(defaults: defaults, key: "baseline").baseline == nil, "Damaged history does not crash or fabricate a previous forecast")
        try check(bill.amount == 100 && bill.status == .pending && !bill.isArchived && salary.amount == 1000, "Comparison and persistence do not mutate transactions")
    }
}
