import Foundation
import SwiftData
#if canImport(SaldoPilot)
@testable import SaldoPilot
#endif
#if canImport(UIKit)
import UIKit
import PDFKit
#endif

@MainActor
enum UnpaidBillsReportVerification {
    enum Failure: Error { case checkFailed }
    static func check(_ value: Bool) throws { if !value { throw Failure.checkFailed } }
    static func run() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Oslo")!
        func date(_ month: Int, _ day: Int, hour: Int = 12) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
        }
        let now = date(11, 19)
        let overdue = Transaction(title: "Overdue bill", amount: 10, type: .expense, dueDate: date(11, 1), status: .overdue)
        let upcoming = Transaction(title: "Upcoming bill", amount: 20, type: .expense, dueDate: date(11, 30, hour: 23))
        let outside = Transaction(title: "Next month", amount: 30, type: .expense, dueDate: date(12, 1, hour: 0))
        let previous = Transaction(title: "Previous month", amount: 40, type: .expense, dueDate: date(10, 31))
        let paid = Transaction(title: "Paid", amount: 50, type: .expense, dueDate: date(11, 20), status: .paid)
        let completed = Transaction(title: "Completed", amount: 60, type: .expense, dueDate: date(11, 20), isCompleted: true)
        let archived = Transaction(title: "Archived", amount: 70, type: .expense, dueDate: date(11, 20), isArchived: true)
        let cancelled = Transaction(title: "Cancelled", amount: 80, type: .expense, dueDate: date(11, 20), status: .cancelled)
        let income = Transaction(title: "Pending income", amount: 90, type: .income, dueDate: date(11, 20))
        let rows = [outside, overdue, archived, paid, upcoming, previous, completed, cancelled, income]
        let month = UnpaidBillsSelection.bills(from: rows, overdueOnly: false, period: .thisMonth, now: now, calendar: calendar)
        try check(month.map(\.id) == [overdue.id, upcoming.id])
        try check(month.reduce(Decimal.zero) { $0 + $1.amount } == 30)
        let singleDay = UnpaidBillsSelection.bills(from: rows, overdueOnly: false, period: .custom, start: date(11, 30), end: date(11, 30), now: now, calendar: calendar)
        try check(singleDay.map(\.id) == [upcoming.id])
        let invalid = UnpaidBillsSelection.bills(from: rows, overdueOnly: false, period: .custom, start: date(11, 30), end: date(11, 1), now: now, calendar: calendar)
        try check(invalid.isEmpty)
        let all = UnpaidBillsSelection.bills(from: rows, overdueOnly: false, period: .allDates, now: now, calendar: calendar)
        try check(all.count == 4)
        let oldReport = UnpaidBillsSelection.bills(from: rows, overdueOnly: true, period: .thisMonth, now: now, calendar: calendar)
        try check(oldReport.map(\.id) == [previous.id, overdue.id])
        let dstInterval = UnpaidBillsSelection.interval(period: .custom, start: date(3, 29), end: date(3, 29), now: now, calendar: calendar)!
        try check(dstInterval.duration == 23 * 3600)
        try check(!overdue.isCompleted && overdue.status == .overdue && upcoming.status == .pending && rows.count == 9)
        #if canImport(UIKit)
        for count in [0, 1, 24, 25, 70] {
            var reportRows: [ReportTransaction] = (0..<count).map { i in
                let transaction = Transaction(title: "Unpaid row \(i)", amount: Decimal(i + 1), type: .expense, dueDate: now.addingTimeInterval(Double(i) * 86400))
                return ReportTransaction(transaction: transaction, transactionDate: transaction.dueDate)
            }
            reportRows.append(ReportTransaction(transaction: income, transactionDate: income.dueDate))
            reportRows.append(ReportTransaction(transaction: paid, transactionDate: paid.dueDate))
            let url = try ReportPDFService.makeUnpaidChecklist(transactions: reportRows, locale: Locale(identifier: "nb_NO"), periodDescription: "1. nov. 2026 - 30. nov. 2026")
            defer { try? FileManager.default.removeItem(at: url) }
            guard let pdf = PDFDocument(url: url), let text = pdf.string else { throw Failure.checkFailed }
            try check(pdf.pageCount > 0 && text.contains("Ubetalte regninger") && text.contains("30. nov. 2026"))
            try check(!text.contains("Pending income"))
            if count > 0 { try check(text.contains("Unpaid row \(count - 1)")) }
            if count == 70 { try check(pdf.pageCount > 1) }
        }
        #endif
    }
}
