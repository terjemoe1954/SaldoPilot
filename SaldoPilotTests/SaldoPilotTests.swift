import Foundation
import Testing
@testable import SaldoPilot

@MainActor
struct SaldoPilotTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test("Currency input accepts Norwegian and English formats")
    func currencyInputFormats() {
        let expected = Decimal(string: "1234.50")!

        #expect(Decimal.currencyAmount(from: "1 234,50") == expected)
        #expect(Decimal.currencyAmount(from: "1.234,50") == expected)
        #expect(Decimal.currencyAmount(from: "1,234.50") == expected)
        #expect(Decimal.currencyAmount(from: "1234.50") == expected)
        #expect(Decimal.currencyAmount(from: "1\u{00A0}234,50 kr") == expected)
        #expect(Decimal.currencyAmount(from: "NOK 1 234,50") == expected)
    }

    @Test("Transaction amounts reject invalid financial input")
    func invalidTransactionAmounts() {
        #expect(Decimal.currencyAmount(from: "0") == nil)
        #expect(Decimal.currencyAmount(from: "-10") == nil)
        #expect(Decimal.currencyAmount(from: "12,3456") == nil)
        #expect(Decimal.currencyAmount(from: "tekst") == nil)
    }

    @Test("Available balance uses only settled activity from the opening date")
    func availableBalance() throws {
        let openingDate = try #require(date(year: 2026, month: 10, day: 1))
        let earlierDate = try #require(date(year: 2026, month: 9, day: 30))
        let receivedIncome = transaction(
            title: "Received",
            amount: 500,
            type: .income,
            date: openingDate,
            status: .received,
            isCompleted: true
        )
        let paidExpense = transaction(
            title: "Paid",
            amount: 200,
            type: .expense,
            date: openingDate,
            status: .paid,
            isCompleted: true
        )
        let pendingExpense = Transaction(
            title: "Pending",
            amount: 900,
            type: .expense,
            dueDate: openingDate
        )
        let earlierExpense = transaction(
            title: "Earlier",
            amount: 400,
            type: .expense,
            date: earlierDate,
            status: .paid,
            isCompleted: true
        )
        let cancelledExpense = transaction(
            title: "Cancelled",
            amount: 300,
            type: .expense,
            date: openingDate,
            status: .cancelled,
            isCompleted: true
        )

        let result = AccountBalanceCalculator.availableBalance(
            openingBalanceText: "1 000,00",
            openingBalanceDate: openingDate,
            transactions: [
                receivedIncome,
                paidExpense,
                pendingExpense,
                earlierExpense,
                cancelledExpense
            ],
            calendar: calendar
        )

        #expect(result == Decimal(1300))
    }

    @Test(
        "Monthly recurrence clamps to valid calendar days",
        arguments: [
            (2024, 1, 31, 2024, 2, 29),
            (2023, 1, 31, 2023, 2, 28),
            (2026, 3, 31, 2026, 4, 30),
            (2026, 4, 30, 2026, 5, 30),
            (2024, 2, 29, 2024, 3, 29),
            (2026, 12, 31, 2027, 1, 31)
        ]
    )
    func monthlyRecurrence(
        sourceYear: Int,
        sourceMonth: Int,
        sourceDay: Int,
        expectedYear: Int,
        expectedMonth: Int,
        expectedDay: Int
    ) throws {
        let sourceDate = try #require(
            date(year: sourceYear, month: sourceMonth, day: sourceDay)
        )
        let expectedDate = try #require(
            date(year: expectedYear, month: expectedMonth, day: expectedDay)
        )
        let item = Transaction(
            title: "Synthetic recurrence",
            amount: 100,
            type: .expense,
            dueDate: sourceDate,
            recurrence: .monthly
        )

        let result = RecurrenceService.nextDueDate(
            after: sourceDate,
            for: item,
            calendar: calendar
        )

        #expect(result == expectedDate)
    }

    private func transaction(
        title: String,
        amount: Decimal,
        type: TransactionType,
        date: Date,
        status: TransactionStatus,
        isCompleted: Bool
    ) -> Transaction {
        Transaction(
            title: title,
            amount: amount,
            type: type,
            dueDate: date,
            paidDate: date,
            status: status,
            isCompleted: isCompleted
        )
    }

    private func date(year: Int, month: Int, day: Int) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day))
    }
}
