import Foundation
import SwiftData
#if canImport(SaldoPilot)
@testable import SaldoPilot
#endif

/// Runs exclusively against fresh, local stores and private UserDefaults suites.
@MainActor
enum BackupRestoreVerification {
    struct Failure: Error, CustomStringConvertible {
        let description: String
    }
    static func check(_ condition: @autoclosure () throws -> Bool, _ message: String) throws {
        if try !condition() { throw Failure(description: message) }
    }
    static func store(_ url: URL) throws -> ModelContainer {
        let schema = Schema(SaldoPilotSchemaV6.models)
        return try ModelContainer(for: schema, configurations: [
            ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        ])
    }
    static func snapshot(_ container: ModelContainer) throws -> Data {
        let context = ModelContext(container)
        let url = try ExportService.makeJSONBackup(
            transactions: context.fetch(FetchDescriptor<Transaction>()),
            budgets: context.fetch(FetchDescriptor<Budget>()),
            categoryDefinitions: context.fetch(FetchDescriptor<CategoryDefinition>())
        )
        defer { try? FileManager.default.removeItem(at: url) }
        var value = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
        value.removeValue(forKey: "exportedAt")
        for key in ["categories", "transactions", "budgets"] {
            value[key] = (value[key] as! [[String: Any]]).sorted {
                String(describing: $0["id"]!) < String(describing: $1["id"]!)
            }
        }
        return try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
    }
    static func run(at root: URL) throws -> [String: Any] {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let source = try store(root.appendingPathComponent("source.store"))
        let targetURL = root.appendingPathComponent("restored.store")
        let target = try store(targetURL)
        let sourceContext = ModelContext(source)
        sourceContext.autosaveEnabled = false
        let preciseDate = Date(timeIntervalSinceReferenceDate: 800_000_000.1234567)
        let customID = "test-hobby-category"
        let collisionID = "testhobbycategory"
        let custom = CategoryDefinition(id: customID, name: "Hobby, æøå / งานอดิเรก", systemImage: "star", colorName: "purple", isHidden: true, excludesFromSavingsTips: true, createdAt: preciseDate, updatedAt: preciseDate)
        let standardOverride = CategoryDefinition(id: CategoryKind.health.rawValue, name: "Egen helse", systemImage: "heart", colorName: "pink", legacyKindRawValue: CategoryKind.health.rawValue, isHidden: true, excludesFromSavingsTips: false, createdAt: preciseDate, updatedAt: preciseDate)
        sourceContext.insert(custom)
        sourceContext.insert(standardOverride)
        sourceContext.insert(CategoryDefinition(id: collisionID, name: "Separate category", systemImage: "tag", colorName: "red", createdAt: preciseDate, updatedAt: preciseDate))
        let seriesID = UUID()
        for (index, recurrence) in RecurrenceRule.allCases.enumerated() {
            let item = Transaction(
                title: index == 0 ? "  Refusjon restaurant  " : "Test \(recurrence.rawValue)",
                amount: Decimal(string: ["0", "1249.50", "32000", "199.99", "0.01", "999999999.99", "100"][index])!,
                type: index % 2 == 0 ? .income : .expense,
                dueDate: preciseDate.addingTimeInterval(Double(index) * 86400),
                paidDate: index % 2 == 0 ? preciseDate : nil,
                status: [.pending, .paid, .received, .cancelled, .overdue][index % 5],
                category: index % 2 == 0 ? .home : .other,
                customCategoryID: index == 2 ? collisionID : index % 2 == 0 ? customID : nil,
                recurrence: recurrence,
                recurrenceIntervalMonths: recurrence == .everyNMonths || recurrence == .custom ? 5 : nil,
                recurrenceSeriesID: recurrence == .none ? nil : seriesID,
                recurrenceAnchorDay: recurrence == .none ? nil : 31,
                notes: "Linje 1, \"anførsel\"\nLinje 2 - æøå ไทย",
                createdAt: preciseDate, updatedAt: preciseDate,
                isCompleted: index % 2 == 0, isArchived: index == 2
            )
            sourceContext.insert(item)
        }
        // Similar-looking records with different IDs must remain distinct.
        for _ in 0..<2 {
            sourceContext.insert(Transaction(title: "Samme tittel", amount: 100, type: .expense, dueDate: preciseDate, category: .health, createdAt: preciseDate, updatedAt: preciseDate))
        }
        for category in [customID, CategoryKind.health.rawValue] {
            sourceContext.insert(Budget(category: category == customID ? .home : .health, customCategoryID: category == customID ? customID : nil, monthStart: preciseDate, amount: Decimal(string: "1599.99")!, createdAt: preciseDate, updatedAt: preciseDate))
        }
        try sourceContext.save()
        let suite = "SaldoPilot.BackupAudit." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("Audit name", forKey: AppSettingsKey.displayName)
        defaults.set("pro", forKey: AppSettingsKey.proStatus)
        defaults.set(true, forKey: AppSettingsKey.allowExternalAI)
        let expectedSettings = BackupAppSettings.capture(from: defaults)
        let backup = try ExportService.makeJSONBackup(
            transactions: ModelContext(source).fetch(FetchDescriptor<Transaction>()),
            budgets: ModelContext(source).fetch(FetchDescriptor<Budget>()),
            categoryDefinitions: ModelContext(source).fetch(FetchDescriptor<CategoryDefinition>()),
            settings: expectedSettings
        )
        let backupData = try Data(contentsOf: backup)
        try backupData.write(to: root.appendingPathComponent("synthetic-backup.json"))
        defer { try? FileManager.default.removeItem(at: backup) }
        defaults.set("Before restore", forKey: AppSettingsKey.displayName)
        defaults.set("free", forKey: AppSettingsKey.proStatus)
        defaults.set(false, forKey: AppSettingsKey.allowExternalAI)
        let summary = try ImportService.importFile(at: backup, modelContext: ModelContext(target), userDefaults: defaults)
        try check(summary.transactionsCreated == 9 && summary.budgetsCreated == 2 && summary.skippedRows == 0, "Incorrect restore counts")
        try check(try snapshot(source) == snapshot(target), "Round-trip changed fields")
        try check(BackupAppSettings.capture(from: defaults) == expectedSettings, "Settings not restored")
        try check(defaults.string(forKey: AppSettingsKey.proStatus) == "free", "Purchase status restored unexpectedly")
        try check(!defaults.bool(forKey: AppSettingsKey.allowExternalAI), "External AI consent restored unexpectedly")
        let repeatSummary = try ImportService.importFile(at: backup, modelContext: ModelContext(target), userDefaults: defaults)
        try check(repeatSummary.transactionsCreated == 0 && repeatSummary.budgetsCreated == 0, "Repeated merge added duplicates")
        try check(try snapshot(source) == snapshot(target), "Repeated merge changed fields")
        let reopened = try store(targetURL)
        try check(try snapshot(source) == snapshot(reopened), "Reopening lost restored data")
        let edit = ModelContext(target)
        let transaction = try edit.fetch(FetchDescriptor<Transaction>()).first!
        transaction.notes = "New local edit"
        try edit.save()
        _ = try ImportService.importFile(at: backup, modelContext: ModelContext(target), userDefaults: defaults)
        try check(try ModelContext(target).fetch(FetchDescriptor<Transaction>()).contains { $0.notes == "New local edit" }, "Merge overwrote a local edit")
        let replace = try ImportService.importFile(at: backup, mode: .replaceExisting, modelContext: ModelContext(target), userDefaults: defaults)
        try check(replace.replacedTransactions == 9 && replace.replacedBudgets == 2, "Replace counts incorrect")
        try check(try snapshot(source) == snapshot(target), "Replace did not restore all fields")

        var object = try JSONSerialization.jsonObject(with: backupData) as! [String: Any]
        let sourceSnapshot = try snapshot(target)
        let file = root.appendingPathComponent("invalid.json")
        func rejected(_ value: [String: Any], name: String) throws {
            try JSONSerialization.data(withJSONObject: value).write(to: file)
            let oldSettings = BackupAppSettings.capture(from: defaults)
            do {
                _ = try ImportService.importFile(at: file, mode: .replaceExisting, modelContext: ModelContext(target), userDefaults: defaults)
                throw Failure(description: "Invalid input accepted: " + name)
            } catch is Failure { throw Failure(description: "Invalid input accepted: " + name) }
            catch { }
            try check(try snapshot(target) == sourceSnapshot, "Invalid input changed data: " + name)
            try check(BackupAppSettings.capture(from: defaults) == oldSettings, "Invalid input changed settings: " + name)
        }
        var invalid = object
        invalid["budgets"] = "damaged"
        try rejected(invalid, name: "damaged budget section")
        invalid = object; invalid["formatVersion"] = 999
        try rejected(invalid, name: "future backup version")
        invalid = object; invalid.removeValue(forKey: "transactions")
        try rejected(invalid, name: "missing transaction section")
        invalid = object
        var rows = invalid["transactions"] as! [[String: Any]]
        rows[0]["amount"] = "not a number"; invalid["transactions"] = rows
        try rejected(invalid, name: "invalid amount")
        invalid = object
        rows = invalid["transactions"] as! [[String: Any]]
        rows.append(rows[0]); invalid["transactions"] = rows
        try rejected(invalid, name: "duplicate record IDs in backup")
        invalid = object; invalid["categories"] = "damaged"
        try rejected(invalid, name: "damaged category section")
        invalid = object; invalid["settings"] = ["language": "broken"]
        try rejected(invalid, name: "damaged settings section")

        invalid = object; invalid["budgets"] = NSNull()
        try rejected(invalid, name: "null budget section")
        invalid = object; invalid["categories"] = NSNull()
        try rejected(invalid, name: "null category section")
        invalid = object
        rows = invalid["transactions"] as! [[String: Any]]
        rows[0].removeValue(forKey: "preciseDates"); invalid["transactions"] = rows
        try rejected(invalid, name: "missing precise timestamps")
        invalid = object
        rows = invalid["transactions"] as! [[String: Any]]
        rows[0]["category"] = "missing-category"; invalid["transactions"] = rows
        try rejected(invalid, name: "dangling category reference")
        invalid = object
        rows = invalid["transactions"] as! [[String: Any]]
        rows[0]["amount"] = "123junk"; invalid["transactions"] = rows
        try rejected(invalid, name: "partially numeric amount")

        // Old V4 ISO dates and backups without categories/budgets still import safely.
        let legacy = root.appendingPathComponent("legacy-v4.json")
        object["formatVersion"] = 4
        let iso = ISO8601DateFormatter()
        for key in ["transactions", "budgets", "categories"] {
            var values = object[key] as! [[String: Any]]
            for index in values.indices {
                for dateKey in ["dueDate", "paidDate", "monthStart", "createdAt", "updatedAt"] {
                    if let seconds = values[index][dateKey] as? Double {
                        values[index][dateKey] = iso.string(from: Date(timeIntervalSinceReferenceDate: seconds))
                    }
                }
                values[index].removeValue(forKey: "excludesFromSavingsTips")
                values[index].removeValue(forKey: "preciseDates")
                values[index].removeValue(forKey: "legacyCategory")
                if key == "categories" { values[index].removeValue(forKey: "isHidden") }
            }
            object[key] = values
        }
        try JSONSerialization.data(withJSONObject: object).write(to: legacy)
        let legacyTarget = try store(root.appendingPathComponent("legacy.store"))
        let legacySummary = try ImportService.importFile(at: legacy, modelContext: ModelContext(legacyTarget), userDefaults: defaults)
        try check(legacySummary.transactionsCreated == 9 && legacySummary.budgetsCreated == 2, "V4 backup not supported")
        let withoutBudgets = root.appendingPathComponent("legacy-without-budgets.json")
        var legacyWithoutBudgets = object
        legacyWithoutBudgets.removeValue(forKey: "budgets")
        legacyWithoutBudgets["transactions"] = (object["transactions"] as! [[String: Any]]).filter {
            ($0["category"] as? String).flatMap(CategoryKind.init(rawValue:)) != nil
        }
        try JSONSerialization.data(withJSONObject: legacyWithoutBudgets).write(to: withoutBudgets)
        _ = try ImportService.importFile(at: withoutBudgets, mode: .replaceExisting, modelContext: ModelContext(legacyTarget), userDefaults: defaults)
        try check(try ModelContext(legacyTarget).fetchCount(FetchDescriptor<Budget>()) == 2, "JSON without budgets lost existing budgets")

        let csv = root.appendingPathComponent("legacy.csv")
        try "id,title,amount,type,dueDate\n\(UUID().uuidString),CSV test,15.50,expense,2026-11-25".write(to: csv, atomically: true, encoding: .utf8)
        let csvSummary = try ImportService.importFile(at: csv, mode: .replaceExisting, modelContext: ModelContext(legacyTarget), userDefaults: defaults)
        try check(csvSummary.budgetsCreated == 0 && csvSummary.replacedBudgets == 0, "CSV replaced budgets")
        try check(try ModelContext(legacyTarget).fetchCount(FetchDescriptor<Budget>()) == 2, "CSV lost existing budgets")
        let csvRepeat = try ImportService.importFile(at: csv, modelContext: ModelContext(legacyTarget), userDefaults: defaults)
        try check(csvRepeat.transactionsCreated == 0, "Repeated CSV with stable IDs duplicated transactions")

        let emptyTarget = try store(root.appendingPathComponent("empty-restore.store"))
        let emptyContext = ModelContext(emptyTarget)
        emptyContext.insert(Transaction(title: "Only in disposable test store", amount: 10, type: .expense, dueDate: preciseDate))
        emptyContext.insert(Budget(category: .home, monthStart: preciseDate, amount: 20))
        try emptyContext.save()
        let emptyBackup = try ExportService.makeJSONBackup(transactions: [], budgets: [], categoryDefinitions: [])
        defer { try? FileManager.default.removeItem(at: emptyBackup) }
        let emptySummary = try ImportService.importFile(at: emptyBackup, mode: .replaceExisting, modelContext: ModelContext(emptyTarget), userDefaults: defaults)
        try check(emptySummary.replacedTransactions == 1 && emptySummary.replacedBudgets == 1, "Empty replacement counts incorrect")
        try check(try ModelContext(emptyTarget).fetchCount(FetchDescriptor<Transaction>()) == 0, "Empty backup did not restore empty state")
        try check(try ModelContext(emptyTarget).fetchCount(FetchDescriptor<Budget>()) == 0, "Empty backup did not restore empty budgets")

        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let january = calendar.date(from: DateComponents(year: 2027, month: 1, day: 31))!
        let restoredRecurring = try ModelContext(target).fetch(FetchDescriptor<Transaction>()).first { $0.recurrence == .monthly }!
        let february = RecurrenceService.nextDueDate(after: january, for: restoredRecurring, calendar: calendar)!
        let march = RecurrenceService.nextDueDate(after: february, for: restoredRecurring, calendar: calendar)!
        try check(calendar.component(.day, from: february) == 28 && calendar.component(.day, from: march) == 31, "Restored month-end anchor changed")
        return ["result": "passed", "transactions": 9, "budgets": 2, "categoryDefinitions": 3,
                "recurrenceRules": RecurrenceRule.allCases.count, "repeatedMergeCreated": 0,
                "allExportedFieldsPreserved": true, "persistedStoreReopened": true,
                "invalidBackupsRejectedWithoutChanges": 12, "legacyV4AndCSV": true, "jsonWithoutBudgetsKeepsExistingBudgets": true, "emptyBackupRestored": true,
                "monthEndAnchorPreserved": true, "settingsAndConsentChecks": true,
                "cloudKit": "disabled in every test store", "storeDirectory": root.path]
    }
}
