import Foundation
import SwiftData
import Testing
@testable import SaldoPilot

@MainActor
enum DashboardHomeVerification {
    static func run() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("HomeAudit-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Oslo")!
        let today = calendar.date(from: DateComponents(year: 2026, month: 11, day: 22))!
        func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: today)! }
        let migrationURL = root.appendingPathComponent("migration.store")
        let txID = UUID(), budgetID = UUID(), series = UUID()
        // Create the exact released V6 schema, then open with the new migration plan.
        do {
            let schema = Schema(SaldoPilotSchemaV6.models)
            let old = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: migrationURL, cloudKitDatabase: .none)])
            let ctx = ModelContext(old)
            ctx.insert(Transaction(id: txID, title: "Regning", amount: Decimal(string: "1249.50")!, type: .expense, dueDate: day(2), recurrence: .monthly, recurrenceSeriesID: series, recurrenceAnchorDay: 24))
            ctx.insert(Budget(id: budgetID, category: .home, monthStart: today, amount: 3000))
            ctx.insert(CategoryDefinition(id: "home-test", name: "Egen kategori", excludesFromSavingsTips: true))
            ctx.insert(ExternalImportReceipt(sourceID: txID.uuidString, transactionID: txID, fingerprint: String(repeating: "a", count: 64), exportedAt: today))
            try ctx.save()
        }
        let schema = Schema(SaldoPilotSchemaV7.models)
        let migrated = try ModelContainer(for: schema, migrationPlan: SaldoPilotMigrationPlan.self, configurations: [ModelConfiguration(schema: schema, url: migrationURL, cloudKitDatabase: .none)])
        let ctx = ModelContext(migrated)
        let transactions = try ctx.fetch(FetchDescriptor<Transaction>())
        #expect(transactions.count == 1)
        #expect(transactions.first?.id == txID && transactions.first?.recurrenceSeriesID == series)
        #expect(transactions.first?.amount == Decimal(string: "1249.50"))
        #expect(try ctx.fetch(FetchDescriptor<Budget>()).first?.id == budgetID)
        #expect(try ctx.fetch(FetchDescriptor<CategoryDefinition>()).first?.excludesFromSavingsTips == true)
        #expect(try ctx.fetchCount(FetchDescriptor<ExternalImportReceipt>()) == 1)
        #expect(try ctx.fetchCount(FetchDescriptor<SavingsGoal>()) == 0)
        // Bill selection includes today through day six, excludes midnight on day seven.
        var bills = [Transaction(title: "Past", amount: 100, type: .expense, dueDate: day(-1)),
                     Transaction(title: "Today", amount: 200, type: .expense, dueDate: today),
                     Transaction(title: "Last second", amount: 300, type: .expense, dueDate: day(7).addingTimeInterval(-1)),
                     Transaction(title: "Next week", amount: 400, type: .expense, dueDate: day(7)),
                     Transaction(title: "Income", amount: 500, type: .income, dueDate: day(-1))]
        for status in [TransactionStatus.paid, .received, .cancelled] {
            bills.append(Transaction(title: "Excluded", amount: 999, type: .expense, dueDate: day(-1), status: status))
        }
        bills.append(Transaction(title: "Completed", amount: 999, type: .expense, dueDate: today, isCompleted: true))
        bills.append(Transaction(title: "Archived", amount: 999, type: .expense, dueDate: today, isArchived: true))
        let result = DashboardBillsSelection.calculate(bills, now: today, calendar: calendar)
        #expect(result.overdue.map(\.title) == ["Past"])
        #expect(result.upcoming.map(\.title) == ["Today", "Last second"])
        #expect(result.total == 600)
        // Saving and deleting goals must not create transactions or recurrences.
        try SavingsGoalSelection.save(nil, name: "Buffer", target: 20000, saved: 12000, date: day(30), in: ctx)
        let goal = try ctx.fetch(FetchDescriptor<SavingsGoal>()).first!
        #expect(goal.progress == 0.6 && goal.remaining == 8000)
        let duplicate = SavingsGoal(id: goal.id, name: "Old copy", targetAmount: 100, updatedAt: .distantPast)
        ctx.insert(duplicate); try ctx.save()
        #expect(SavingsGoalSelection.preferred(try ctx.fetch(FetchDescriptor<SavingsGoal>())).count == 1)
        #expect(SavingsGoalSelection.preferred([duplicate, goal]).first?.name == "Buffer")
        let url = try ExportService.makeJSONBackup(transactions: transactions,
                    budgets: ctx.fetch(FetchDescriptor<Budget>()), categoryDefinitions: ctx.fetch(FetchDescriptor<CategoryDefinition>()),
                    importReceipts: ctx.fetch(FetchDescriptor<ExternalImportReceipt>()), savingsGoals: ctx.fetch(FetchDescriptor<SavingsGoal>()))
        defer { try? FileManager.default.removeItem(at: url) }
        let target = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: root.appendingPathComponent("target.store"), cloudKitDatabase: .none)])
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        _ = try ImportService.importFile(at: url, modelContext: target.mainContext, userDefaults: defaults)
        _ = try ImportService.importFile(at: url, modelContext: target.mainContext, userDefaults: defaults)
        var check = ModelContext(target)
        var restored = try check.fetch(FetchDescriptor<SavingsGoal>())
        #expect(restored.count == 1 && restored[0].id == goal.id && restored[0].savedAmount == 12000)
        #expect(restored[0].targetDate == goal.targetDate && restored[0].updatedAt == goal.updatedAt)
        #expect(try check.fetchCount(FetchDescriptor<Transaction>()) == 1)
        // Merge preserves an edited local goal; replace restores the backup explicitly.
        try SavingsGoalSelection.save(restored[0], name: "Local edit", target: 25000, saved: 13000, date: nil, in: check)
        _ = try ImportService.importFile(at: url, modelContext: target.mainContext, userDefaults: defaults)
        check = ModelContext(target)
        #expect(try check.fetch(FetchDescriptor<SavingsGoal>()).first?.name == "Local edit")
        _ = try ImportService.importFile(at: url, mode: .replaceExisting, modelContext: target.mainContext, userDefaults: defaults)
        check = ModelContext(target); restored = try check.fetch(FetchDescriptor<SavingsGoal>())
        #expect(restored.count == 1 && restored[0].name == "Buffer")
        // Tombstones survive backups and repeated merge, with no resurrection.
        try SavingsGoalSelection.delete(restored[0], in: check)
        _ = try ImportService.importFile(at: url, modelContext: target.mainContext, userDefaults: defaults)
        #expect(try ModelContext(target).fetch(FetchDescriptor<SavingsGoal>()).allSatisfy(\.isDeleted))
        #expect(try ctx.fetchCount(FetchDescriptor<Transaction>()) == 1)
        #expect(transactions[0].status == .pending && !transactions[0].isCompleted)
        // Invalid goal payload must reject the entire backup, before any mutation.
        var object = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
        var invalid = object["savingsGoals"] as! [[String: Any]]
        invalid[0]["targetAmount"] = -1; object["savingsGoals"] = invalid
        let broken = root.appendingPathComponent("broken.json")
        try JSONSerialization.data(withJSONObject: object).write(to: broken)
        do {
            _ = try ImportService.importFile(at: broken, mode: .replaceExisting, modelContext: target.mainContext, userDefaults: defaults)
            Issue.record("Invalid savings goal was accepted")
        } catch { #expect(error is BackupImportError) }
        #expect(try ModelContext(target).fetch(FetchDescriptor<SavingsGoal>()).allSatisfy(\.isDeleted))
        // Legacy files lacking goals never erase local goals in replace mode.
        object.removeValue(forKey: "savingsGoals"); object["formatVersion"] = 6
        let legacy = root.appendingPathComponent("legacy.json")
        try JSONSerialization.data(withJSONObject: object).write(to: legacy)
        _ = try ImportService.importFile(at: legacy, mode: .replaceExisting, modelContext: target.mainContext, userDefaults: defaults)
        #expect(try ModelContext(target).fetchCount(FetchDescriptor<SavingsGoal>()) == 1)
    }
}
