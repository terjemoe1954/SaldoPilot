import Foundation
import PDFKit
import SwiftData
import Testing
@testable import SaldoPilot

@MainActor
struct SaldoPilotTests {
    @Test("One early payout updates forecast boundaries without shifting normal recurrence or creating rows")
    func earlyPayoutDate() throws { try PaydayDateVerification.run() }

    @Test("New home preserves bill boundaries, migrates V6 and round-trips goals without cash-flow mutations")
    func newHomeAndSavingsGoals() throws {
        try DashboardHomeVerification.run()
    }

    @Test("Unpaid bill checklist uses inclusive date boundaries and excludes settled, archived, cancelled and income rows")
    func unpaidBillChecklist() throws {
        try UnpaidBillsReportVerification.run()
    }

    @Test("Payment date selection preserves due dates and does not duplicate recurrence on repeated saves")
    func paymentDateSelection() throws {
        try TransactionSettlementVerification.run()
    }

    @Test("Final audit preserves independent recurrence series and restores duplicate category definitions safely")
    func stabilityAudit() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("SaldoPilot-Stability-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try StabilityVerification.run(at: root)
    }

    @Test("Forecast explanations reconcile exactly and preserve a fixed comparison baseline")
    func forecastChanges() throws {
        try ForecastChangesVerification.run()
    }

    @Test("Salary selection sync converges across three devices without changing data")
    func forecastSalarySelectionSync() throws {
        try ForecastSalarySelectionVerification.run()
    }

    @Test("Payday forecast separates settled balance, pending income and recurring bills without mutations")
    func paydayForecast() throws {
        try PaydayForecastVerification.run()
    }

    @Test("Sync tracks overlapping events and keeps export errors until export recovers")
    func syncOverlappingEventsAndRecovery() {
        var state = CloudSyncState()
        let upload = UUID(), download = UUID()
        let date = Date(timeIntervalSince1970: 100)
        state.receive(id: upload, operation: .upload, endedAt: nil, succeeded: false, failure: nil)
        state.receive(id: download, operation: .download, endedAt: nil, succeeded: false, failure: nil)
        state.receive(id: upload, operation: .upload, endedAt: date, succeeded: false,
                      failure: .init(date: date, domain: "CKErrorDomain", code: 2))
        #expect(state.isSyncing)
        state.receive(id: download, operation: .download, endedAt: date, succeeded: true, failure: nil)
        #expect(!state.isSyncing)
        #expect(state.latestFailure?.code == 2)
        #expect(state.lastUpload == nil)
        #expect(state.lastDownload == date)
        state.receive(id: UUID(), operation: .setup, endedAt: date, succeeded: true, failure: nil)
        #expect(state.latestFailure != nil)
        state.receive(id: UUID(), operation: .upload, endedAt: date.addingTimeInterval(1), succeeded: true, failure: nil)
        #expect(state.latestFailure == nil)
        #expect(state.lastSuccess == date.addingTimeInterval(1))
    }

    @Test("Setup is not a successful sync and timestamps never move backwards")
    func syncSetupAndTimestamps() {
        var state = CloudSyncState()
        let date = Date(timeIntervalSince1970: 100)
        state.receive(id: UUID(), operation: .setup, endedAt: date, succeeded: true, failure: nil)
        #expect(state.lastSuccess == nil)
        state.receive(id: UUID(), operation: .upload, endedAt: date, succeeded: true, failure: nil)
        state.receive(id: UUID(), operation: .upload, endedAt: date.addingTimeInterval(-1), succeeded: true, failure: nil)
        #expect(state.lastUpload == date)
        state.receive(id: UUID(), operation: .download, endedAt: date, succeeded: false, failure: nil)
        #expect(state.latestFailure != nil)
    }

    @Test("Backup restores all fields, survives reopen and repeated imports, and rejects damaged files")
    func backupRestoreRoundTrip() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("SaldoPilot-BackupTests-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let result = try BackupRestoreVerification.run(at: root)
        #expect(result["result"] as? String == "passed")
    }

    @Test("Duplicate category IDs resolve consistently without removing records")
    func duplicateCategoryDefinitions() {
        let old = CategoryDefinition(id: "home", name: "Old", excludesFromSavingsTips: true, updatedAt: Date(timeIntervalSince1970: 1))
        let new = CategoryDefinition(id: "home", name: "New", excludesFromSavingsTips: false, updatedAt: Date(timeIntervalSince1970: 2))
        let custom = CategoryDefinition(id: "custom-test", name: "Custom")
        let duplicate = CategoryDefinition(id: "custom-test", name: "Custom updated", updatedAt: custom.updatedAt.addingTimeInterval(1))
        let input = [old, new, custom, duplicate]
        let options = CategoryOption.available(definitions: input, locale: Locale(identifier: "nb"))
        #expect(Set(options.map(\.id)).count == options.count)
        #expect(options.first { $0.id == "home" }?.name == "New")
        #expect(!CategoryOption.excludesFromSavingsTips(id: "home", definitions: input))
        #expect(CategoryOption.available(definitions: input.reversed(), locale: Locale(identifier: "nb")) == options)
        #expect(input.count == 4)
    }

    @Test("Fixed-cost categories are excluded by default and category overrides control savings tips")
    func savingsTipCategoryExclusions() {
        let now = Date.now
        func expense(_ category: CategoryKind, amount: Decimal) -> Transaction {
            Transaction(title: category.rawValue, amount: amount, type: .expense, dueDate: now, status: .paid, category: category, isCompleted: true)
        }
        let tax = expense(.deduction, amount: 1000)
        let home = expense(.home, amount: 900)
        let insurance = expense(.insurance, amount: 800)
        let groceries = expense(.groceries, amount: 50)
        let input = [tax, home, insurance, groceries]
        let insight = AIInsightEngine.insights(transactions: input).first { $0.id == "savings" }
        #expect(insight?.transactionIDs == [groceries.id])
        #expect(!AIInsightEngine.insights(transactions: [tax, home, insurance]).contains { $0.id == "savings" })
        let override = CategoryDefinition(id: CategoryKind.home.rawValue, name: "Home", legacyKindRawValue: CategoryKind.home.rawValue, excludesFromSavingsTips: false)
        #expect(AIInsightEngine.insights(transactions: input, categoryDefinitions: [override]).first { $0.id == "savings" }?.transactionIDs == [home.id])
        override.excludesFromSavingsTips = true
        #expect(AIInsightEngine.insights(transactions: input, categoryDefinitions: [override]).first { $0.id == "savings" }?.transactionIDs == [groceries.id])
    }

    @Test("V4 categories migrate without losing data and gain default savings-tip policy")
    func savingsCategoryMigration() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("SaldoPilot-V4-Savings-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("migration.store")
        let id = UUID()
        func createV4() throws {
            let schema = Schema(SaldoPilotSchemaV4.models)
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
            container.mainContext.insert(SaldoPilotSchemaV4.Transaction(id: id, title: "Retained transaction", amount: 123, type: .expense, dueDate: .now, category: .insurance))
            container.mainContext.insert(SaldoPilotSchemaV4.CategoryDefinition(id: CategoryKind.insurance.rawValue, name: "My insurance", legacyKindRawValue: CategoryKind.insurance.rawValue))
            try container.mainContext.save()
        }
        try createV4()
        let schema = Schema(SaldoPilotSchemaV7.models)
        let container = try ModelContainer(for: schema, migrationPlan: SaldoPilotMigrationPlan.self, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
        let items = try container.mainContext.fetch(FetchDescriptor<Transaction>())
        let definitions = try container.mainContext.fetch(FetchDescriptor<CategoryDefinition>())
        #expect(items.count == 1 && items.first?.id == id && items.first?.amount == 123)
        #expect(definitions.first?.name == "My insurance")
        #expect(definitions.first?.excludesFromSavingsTips == nil)
        #expect(CategoryOption.excludesFromSavingsTips(id: CategoryKind.insurance.rawValue, definitions: definitions))
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test("AI cards retain the exact transactions behind their summaries")
    func insightTransactionLinks() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let tomorrow = try #require(calendar.date(byAdding: .day, value: 1, to: today))
        let monthStart = try #require(calendar.dateInterval(of: .month, for: today)).start
        let previousMonth = try #require(calendar.date(byAdding: .day, value: -1, to: monthStart))
        let first = Transaction(title: "Internet", amount: 500, type: .expense, dueDate: today)
        let duplicate = Transaction(title: "Internet", amount: 500, type: .expense, dueDate: today)
        let previous = Transaction(title: "Old expense", amount: 100, type: .expense, dueDate: previousMonth)
        let future = Transaction(title: "Next payment", amount: 200, type: .expense, dueDate: tomorrow)
        let cancelled = Transaction(title: "Cancelled", amount: 999, type: .expense, dueDate: today, status: .cancelled)
        let archived = Transaction(title: "Archived", amount: 999, type: .expense, dueDate: today, isArchived: true)
        let input = [first, duplicate, previous, future, cancelled, archived]
        let insights = AIInsightEngine.insights(transactions: input, calendar: calendar)
        func ids(_ name: String) throws -> Set<UUID> {
            Set(try #require(insights.first { $0.id == name }).transactionIDs)
        }
        #expect(try ids("duplicate") == Set([first.id, duplicate.id]))
        #expect(try ids("recurring") == Set([first.id, duplicate.id]))
        #expect(try ids("dueSoon") == Set([first.id, duplicate.id, future.id]))
        let month = try #require(calendar.dateInterval(of: .month, for: today))
        #expect(try ids("situation") == Set([first, duplicate, future].filter { month.containsHalfOpen($0.dueDate) }.map(\.id)))
        #expect(try ids("spendingChange") == Set([first, duplicate, previous, future].filter {
            $0.dueDate < month.end
        }.map(\.id)))
        #expect(insights.allSatisfy { !$0.transactionIDs.contains(cancelled.id) && !$0.transactionIDs.contains(archived.id) })
        #expect(AIInsightEngine.insights(transactions: []).allSatisfy { $0.transactionIDs.isEmpty })
    }

    @Test("Natural entry separates Norwegian amounts, due dates and recurrence")
    func naturalEntryNorwegian() throws {
        let now = try #require(date(year: 2026, month: 11, day: 16))
        let draft = try NaturalTransactionDraftParser.parse(
            "Legg inn strømregning på 1 249,50 kroner, forfall 25. november, hver måned",
            now: now, calendar: calendar
        )
        #expect(draft.title == "strømregning")
        #expect(draft.amount == Decimal(string: "1249.50")!)
        #expect(draft.dueDate == date(year: 2026, month: 11, day: 25))
        #expect(draft.recurrence == .monthly)
        #expect(draft.reviewItems.contains(.inferredYear))
    }

    @Test("Currency decimals are not dates, and relative dates use the supplied clock")
    func naturalEntryAmountsAndDates() throws {
        let now = try #require(date(year: 2026, month: 12, day: 31))
        let draft = try NaturalTransactionDraftParser.parse("Add coffee 49.50 NOK due tomorrow", now: now, calendar: calendar)
        #expect(draft.amount == Decimal(string: "49.50")!)
        #expect(draft.dueDate == date(year: 2027, month: 1, day: 1))
        let income = try NaturalTransactionDraftParser.parse("Legg inn lønn 32000 kr 2027-01-15", now: now, calendar: calendar)
        #expect(income.type == .income)
        #expect(income.amount == 32000)
        #expect(income.dueDate == date(year: 2027, month: 1, day: 15))
        let interval = try NaturalTransactionDraftParser.parse("Forsikring 500 kr om 7 dager hver 3. måned", now: now, calendar: calendar)
        #expect(interval.amount == 500)
        #expect(interval.recurrence == .everyNMonths)
        #expect(interval.recurrenceIntervalMonths == 3)
        #expect(interval.dueDate == date(year: 2027, month: 1, day: 7))
    }

    @Test("Missing and invalid facts remain unfilled and visible for review")
    func naturalEntryMissingFacts() throws {
        let now = try #require(date(year: 2026, month: 11, day: 16))
        let missing = try NaturalTransactionDraftParser.parse("Strømregning", now: now, calendar: calendar)
        #expect(missing.amount == nil && missing.dueDate == nil)
        #expect(missing.reviewItems.contains(.missingAmount))
        #expect(missing.reviewItems.contains(.missingDate))
        let invalid = try NaturalTransactionDraftParser.parse("Strøm 1000 kr forfall 31.02.2027", now: now, calendar: calendar)
        #expect(invalid.amount == 1000)
        #expect(invalid.dueDate == nil)
        #expect(invalid.reviewItems.contains(.unclearDate))
        let negative = try NaturalTransactionDraftParser.parse("Strøm -100 kr i morgen", now: now, calendar: calendar)
        #expect(negative.amount == nil)
        let weekly = try NaturalTransactionDraftParser.parse("Mat 500 kr i morgen ukentlig", now: now, calendar: calendar)
        #expect(weekly.recurrence == .none)
        #expect(weekly.reviewItems.contains(.unclearRecurrence))
    }

    @Test("Natural entry rejects multiple amounts and foreign currency")
    func naturalEntryAmbiguity() throws {
        #expect(throws: NaturalTransactionDraftError.self) {
            try NaturalTransactionDraftParser.parse("Strøm 1000 kr og internett 500 kr i morgen")
        }
        #expect(throws: NaturalTransactionDraftError.self) {
            try NaturalTransactionDraftParser.parse("Hotel 150 EUR due tomorrow")
        }
        #expect(throws: NaturalTransactionDraftError.self) {
            try NaturalTransactionDraftParser.parse(String(repeating: "x", count: 501))
        }
    }

    @Test("On-device language output must be grounded in the original text")
    func naturalEntryModelGrounding() throws {
        let original = try NaturalTransactionDraftParser.parse("Arbeidsgiver overfører 32000 kr i morgen")
        let hallucinated = NaturalTransactionLanguageFields(title: "Invented description", kind: "income", kindEvidence: "salary")
        let unchanged = NaturalTransactionDraftService.applying(hallucinated, to: original)
        #expect(unchanged == original)
        let grounded = NaturalTransactionLanguageFields(title: "Arbeidsgiver", kind: "income", kindEvidence: "Arbeidsgiver overfører")
        let improved = NaturalTransactionDraftService.applying(grounded, to: original)
        #expect(improved.title == "Arbeidsgiver")
        #expect(improved.type == .income)
        #expect(improved.amount == original.amount && improved.dueDate == original.dueDate)
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
        let schema = Schema(SaldoPilotSchemaV7.models)

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

    @Test("A copied V2 store upgrades to V4 without changing financial data")
    func migratesCopiedV2StoreToV4() throws {
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

        let currentSchema = Schema(SaldoPilotSchemaV7.models)
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
        #expect(transactions.allSatisfy { $0.customCategoryID == nil })
        #expect(budgets.allSatisfy { $0.customCategoryID == nil })
        #expect(budgets.first?.amount == Decimal(string: "9000.00")!)
        #expect(transactions.allSatisfy { $0.recurrenceSeriesID == nil })
        #expect(transactions.allSatisfy { $0.recurrenceAnchorDay == nil })
    }

    @Test("Released V3 stores migrate and reopen without losing records or recurrence data")
    func migratesReleasedV3StoreToV4() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "V3.store")
        let transactionID = UUID()
        let budgetID = UUID()
        let seriesID = UUID()
        let dueDate = try #require(date(year: 2026, month: 10, day: 31))
        let createdAt = dueDate.addingTimeInterval(-1000)
        let updatedAt = dueDate.addingTimeInterval(-500)

        do {
            let schema = Schema(SaldoPilotSchemaV3.models)
            let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
            let old = try ModelContainer(for: schema, configurations: [configuration])
            old.mainContext.insert(SaldoPilotSchemaV3.Transaction(
                id: transactionID, title: "Historic payment", amount: Decimal(string: "1234.56")!,
                type: .expense, dueDate: dueDate, paidDate: dueDate, status: .paid,
                category: .home, recurrence: .everyNMonths, recurrenceIntervalMonths: 2,
                recurrenceSeriesID: seriesID, recurrenceAnchorDay: 31, notes: "Keep this note",
                createdAt: createdAt, updatedAt: updatedAt, isCompleted: true, isArchived: true
            ))
            old.mainContext.insert(SaldoPilotSchemaV3.Budget(
                id: budgetID, category: .home, monthStart: dueDate, amount: 9000,
                createdAt: createdAt, updatedAt: updatedAt
            ))
            try old.mainContext.save()
        }

        // Verify both the upgrade and a subsequent app launch on the upgraded store.
        for _ in 0..<2 {
            let schema = Schema(SaldoPilotSchemaV7.models)
            let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
            let upgraded = try ModelContainer(
                for: schema, migrationPlan: SaldoPilotMigrationPlan.self, configurations: [configuration]
            )
            let transactions = try upgraded.mainContext.fetch(FetchDescriptor<Transaction>())
            let budgets = try upgraded.mainContext.fetch(FetchDescriptor<Budget>())
            #expect(transactions.count == 1)
            let transaction = try #require(transactions.first)
            #expect(transaction.id == transactionID)
            #expect(transaction.title == "Historic payment")
            #expect(transaction.amount == Decimal(string: "1234.56")!)
            #expect(transaction.type == .expense)
            #expect(transaction.dueDate == dueDate)
            #expect(transaction.paidDate == dueDate)
            #expect(transaction.status == .paid)
            #expect(transaction.category == .home)
            #expect(transaction.recurrence == .everyNMonths)
            #expect(transaction.recurrenceIntervalMonths == 2)
            #expect(transaction.recurrenceSeriesID == seriesID)
            #expect(transaction.recurrenceAnchorDay == 31)
            #expect(transaction.notes == "Keep this note")
            #expect(transaction.createdAt == createdAt)
            #expect(transaction.updatedAt == updatedAt)
            #expect(transaction.isCompleted && transaction.isArchived)
            #expect(transaction.customCategoryID == nil)
            #expect(budgets.count == 1)
            let budget = try #require(budgets.first)
            #expect(budget.id == budgetID)
            #expect(budget.category == .home)
            #expect(budget.monthStart == dueDate)
            #expect(budget.amount == 9000)
            #expect(budget.createdAt == createdAt && budget.updatedAt == updatedAt)
            #expect(budget.customCategoryID == nil)
        }
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
        let refundExpense = Transaction(
            title: "Feilført refusjon",
            amount: 200,
            type: .expense,
            dueDate: .now,
            category: .refund
        )

        #expect(!savings.isIncludedInOrdinaryCashFlow)
        #expect(!adjustment.isIncludedInOrdinaryCashFlow)
        #expect(refund.isIncludedInOrdinaryCashFlow)
        #expect(refund.isIncludedInCategoryActivity)
        #expect(!refundExpense.isIncludedInOrdinaryCashFlow)
        #expect(refundExpense.isIncludedInCategoryActivity)
        #expect(ordinary.isIncludedInOrdinaryCashFlow)
        #expect(ordinary.isIncludedInCategoryActivity)
        #expect(!savings.isIncludedInCategoryActivity)
        #expect(!adjustment.isIncludedInCategoryActivity)
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
