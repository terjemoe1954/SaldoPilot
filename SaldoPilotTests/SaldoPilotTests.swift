import Foundation
import PDFKit
import SwiftData
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

    @Test("CSV export is UTF-8 and prevents spreadsheet formula execution")
    func safeCSVExport() throws {
        let transaction = Transaction(
            title: "=2+2",
            amount: 100,
            type: .expense,
            dueDate: try #require(date(year: 2026, month: 10, day: 14)),
            notes: "@SUM(A1:A2)"
        )
        let url = try ExportService.makeCSVExport(transactions: [transaction])
        defer { try? FileManager.default.removeItem(at: url) }

        let data = try Data(contentsOf: url)
        #expect(data.starts(with: [0xEF, 0xBB, 0xBF]))
        let text = try #require(String(data: data, encoding: .utf8))
        #expect(text.contains("\"'=2+2\""))
        #expect(text.contains("\"'@SUM(A1:A2)\""))
    }

    @Test("PDF reports handle boundary-sized synthetic datasets")
    func reportPDFBoundarySizes() throws {
        let monthStart = try #require(date(year: 2026, month: 10, day: 1))

        for count in [0, 1, 50, 1_000] {
            let reportTransactions = (0..<count).map { index in
                let transaction = Transaction(
                    title: index == count - 1
                        ? "Boundary item \(index) with a long descriptive title"
                        : "Boundary item \(index)",
                    amount: index == count - 1 ? Decimal(string: "999999999.99")! : Decimal(index + 1),
                    type: index.isMultiple(of: 2) ? .income : .expense,
                    dueDate: monthStart,
                    notes: index == count - 1
                        ? String(repeating: "Long report note ", count: 80)
                        : ""
                )
                return ReportTransaction(transaction: transaction, transactionDate: monthStart)
            }

            let url = try ReportPDFService.makeMonthlyReport(
                transactions: reportTransactions,
                monthStart: monthStart,
                locale: Locale(identifier: "en_NO"),
                dateType: .dueDate,
                reportTitle: "Boundary report",
                selectionDescription: "Synthetic local test data"
            )
            defer { try? FileManager.default.removeItem(at: url) }

            let document = try #require(PDFDocument(url: url))
            let text = document.string ?? ""
            #expect(document.pageCount > 0)
            #expect(text.contains("Count: \(count)"))
            #expect((try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) > 0)
        }
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

    @Test("Monthly recurrence returns to the anchored day after a short month")
    func monthlyRecurrencePreservesAnchorDay() throws {
        let february = try #require(date(year: 2024, month: 2, day: 29))
        let march = try #require(date(year: 2024, month: 3, day: 31))
        #expect(
            RecurrenceService.nextDueDate(
                after: february,
                anchorDay: 31,
                monthInterval: 1,
                calendar: calendar
            ) == march
        )
    }

    @Test("A local test store preserves transactions after reopening")
    func persistentLocalTestStore() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appending(path: "PersistenceTest.store", directoryHint: .notDirectory)
        let schema = Schema(SaldoPilotSchemaV3.models)

        do {
            let configuration = ModelConfiguration(
                "PersistenceTest",
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(
                for: schema,
                migrationPlan: SaldoPilotMigrationPlan.self,
                configurations: [configuration]
            )
            let transaction = Transaction(
                title: "Restart test",
                amount: 321,
                type: .expense,
                dueDate: try #require(date(year: 2026, month: 10, day: 14))
            )
            container.mainContext.insert(transaction)
            try container.mainContext.save()
        }

        let configuration = ModelConfiguration(
            "PersistenceTest",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let reopenedContainer = try ModelContainer(
            for: schema,
            migrationPlan: SaldoPilotMigrationPlan.self,
            configurations: [configuration]
        )
        let reopenedTransactions = try reopenedContainer.mainContext.fetch(FetchDescriptor<Transaction>())

        #expect(reopenedTransactions.count == 1)
        #expect(reopenedTransactions.first?.title == "Restart test")
        #expect(reopenedTransactions.first?.amount == Decimal(321))
    }

    @Test("A copied V2 store upgrades to V3 without changing financial data")
    func migratesCopiedV2StoreToV3() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appending(path: "MigrationTest.store", directoryHint: .notDirectory)
        let firstID = UUID()
        let secondID = UUID()

        do {
            let oldSchema = Schema(SaldoPilotSchemaV2.models)
            let configuration = ModelConfiguration(
                "MigrationTest",
                schema: oldSchema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            let oldContainer = try ModelContainer(
                for: oldSchema,
                configurations: [configuration]
            )
            oldContainer.mainContext.insert(SaldoPilotSchemaV2.Transaction(
                id: firstID,
                title: "Old expense",
                amount: Decimal(string: "123.45")!,
                type: .expense,
                dueDate: try #require(date(year: 2026, month: 1, day: 31)),
                recurrence: .monthly
            ))
            oldContainer.mainContext.insert(SaldoPilotSchemaV2.Transaction(
                id: secondID,
                title: "Old income",
                amount: Decimal(string: "500.00")!,
                type: .income,
                dueDate: try #require(date(year: 2026, month: 2, day: 1))
            ))
            oldContainer.mainContext.insert(SaldoPilotSchemaV2.Budget(
                category: .home,
                monthStart: try #require(date(year: 2026, month: 1, day: 1)),
                amount: Decimal(string: "9000.00")!
            ))
            try oldContainer.mainContext.save()
        }

        let currentSchema = Schema(SaldoPilotSchemaV3.models)
        let configuration = ModelConfiguration(
            "MigrationTest",
            schema: currentSchema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let upgradedContainer = try ModelContainer(
            for: currentSchema,
            migrationPlan: SaldoPilotMigrationPlan.self,
            configurations: [configuration]
        )
        let transactions = try upgradedContainer.mainContext.fetch(FetchDescriptor<Transaction>())
        let budgets = try upgradedContainer.mainContext.fetch(FetchDescriptor<Budget>())

        #expect(transactions.count == 2)
        #expect(Set(transactions.map(\.id)) == [firstID, secondID])
        #expect(transactions.reduce(Decimal.zero) { $0 + $1.amount } == Decimal(string: "623.45")!)
        #expect(budgets.count == 1)
        #expect(budgets.first?.amount == Decimal(string: "9000.00")!)
        #expect(transactions.allSatisfy { $0.recurrenceSeriesID == nil })
        #expect(transactions.allSatisfy { $0.recurrenceAnchorDay == nil })
    }

    @Test("Category standardization only moves explicit matches")
    func categoryStandardizationRules() {
        let fastFood = Transaction(
            title: "Burger King",
            amount: 149,
            type: .expense,
            dueDate: .now,
            category: .other,
            notes: "Keep this note"
        )
        let mobilePackage = Transaction(
            title: "Mobil og TV-pakke",
            amount: 799,
            type: .expense,
            dueDate: .now,
            category: .subscriptions
        )
        let unclear = Transaction(
            title: "Ukjent kjøp",
            amount: 50,
            type: .expense,
            dueDate: .now,
            category: .other
        )
        let restaurant = Transaction(
            title: "Kafé og restaurant",
            amount: 280,
            type: .expense,
            dueDate: .now,
            category: .other
        )
        let manuallyCategorized = Transaction(
            title: "Burger King",
            amount: 149,
            type: .expense,
            dueDate: .now,
            category: .gifts
        )

        #expect(CategoryStandardizationService.standardizedCategory(for: fastFood) == .diningOut)
        #expect(CategoryStandardizationService.standardizedCategory(for: mobilePackage) == .communication)
        #expect(CategoryStandardizationService.standardizedCategory(for: restaurant) == .diningOut)
        #expect(CategoryStandardizationService.standardizedCategory(for: manuallyCategorized) == nil)
        #expect(CategoryStandardizationService.standardizedCategory(for: unclear) == nil)
        #expect(fastFood.amount == 149)
        #expect(fastFood.notes == "Keep this note")
    }

    @Test("Savings transfers and balance adjustments are outside ordinary cash flow")
    func ordinaryCashFlowExclusions() {
        let savings = Transaction(
            title: "Overføring til sparekonto",
            amount: 1_000,
            type: .expense,
            dueDate: .now,
            category: .savings
        )
        let adjustment = Transaction(
            title: "Saldojustering",
            amount: 25,
            type: .income,
            dueDate: .now
        )
        let ordinary = Transaction(
            title: "Dagligvarer",
            amount: 500,
            type: .expense,
            dueDate: .now,
            category: .groceries
        )
        let refund = Transaction(
            title: "Refusjon",
            amount: 200,
            type: .income,
            dueDate: .now,
            category: .refund
        )

        #expect(!savings.isIncludedInOrdinaryCashFlow)
        #expect(!adjustment.isIncludedInOrdinaryCashFlow)
        #expect(!refund.isIncludedInOrdinaryCashFlow)
        #expect(ordinary.isIncludedInOrdinaryCashFlow)
    }

    @Test("Category suggestions prefer history and can link reimbursements")
    func categorySuggestions() {
        let groceryPurchase = Transaction(
            title: "Coop Mega",
            amount: 600,
            type: .expense,
            dueDate: .now,
            category: .groceries
        )
        let historicalChoice = Transaction(
            title: "Fast leverandør",
            amount: 300,
            type: .expense,
            dueDate: .now,
            category: .health
        )

        #expect(
            CategorySuggestionService.suggestion(
                for: "Fast leverandør",
                using: [groceryPurchase, historicalChoice]
            ) == .health
        )
        #expect(
            CategorySuggestionService.suggestion(
                for: "Tilbakebetaling av utlegg Coop Mega",
                using: [groceryPurchase]
            ) == .groceries
        )
        #expect(CategorySuggestionService.suggestion(for: "Burger King", using: []) == .diningOut)
        #expect(CategorySuggestionService.suggestion(for: "Refusjon", using: []) == .refund)
        #expect(CategorySuggestionService.suggestion(for: "Uklar", using: []) == nil)
    }

    @Test("Exports use unique filenames and refuse overwriting")
    func uniqueExportFilenames() throws {
        let first = try ExportService.makeJSONBackup(transactions: [])
        let second = try ExportService.makeJSONBackup(transactions: [])
        defer {
            try? FileManager.default.removeItem(at: first)
            try? FileManager.default.removeItem(at: second)
        }

        #expect(first != second)
        #expect(FileManager.default.fileExists(atPath: first.path))
        #expect(FileManager.default.fileExists(atPath: second.path))
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
