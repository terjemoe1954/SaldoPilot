import Foundation
import SwiftData
#if canImport(SaldoPilot)
@testable import SaldoPilot
#endif

@MainActor
enum StabilityVerification {
    struct Failure: Error { let message: String }
    static func run(at root: URL) throws {
        func check(_ value: Bool, _ message: String) throws { if !value { throw Failure(message: message) } }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let container = try BackupRestoreVerification.store(root.appendingPathComponent("recurrence.store"))
        let context = ModelContext(container)
        context.autosaveEnabled = false
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Oslo")!
        func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
        }
        let firstID = UUID(), secondID = UUID()
        let first = Transaction(title: "Same bill", amount: 100, type: .expense, dueDate: date(2024,1,31), recurrence: .monthly, recurrenceSeriesID: firstID, recurrenceAnchorDay: 31)
        let second = Transaction(title: "Same bill", amount: 100, type: .expense, dueDate: date(2024,1,31), recurrence: .monthly, recurrenceSeriesID: secondID, recurrenceAnchorDay: 31)
        context.insert(first); context.insert(second)
        try RecurrenceService.insertNextOccurrenceIfNeeded(after: first, in: context, calendar: calendar)
        try RecurrenceService.insertNextOccurrenceIfNeeded(after: first, in: context, calendar: calendar)
        var rows = try context.fetch(FetchDescriptor<Transaction>())
        try check(rows.count == 3, "Repeated next occurrence must be idempotent before save")
        try check(second.recurrenceSeriesID == secondID && first.recurrenceSeriesID == firstID, "Identical explicit series must remain independent")
        let february = rows.first { $0.recurrenceSeriesID == firstID && $0.id != first.id }!
        try check(february.dueDate == date(2024,2,29), "Leap day clamp")
        try context.save()
        try RecurrenceService.insertNextOccurrenceIfNeeded(after: first, in: context, calendar: calendar)
        try RecurrenceService.insertNextOccurrenceIfNeeded(after: second, in: context, calendar: calendar)
        try context.save()
        rows = try context.fetch(FetchDescriptor<Transaction>())
        try check(rows.count == 4, "Saved or restored occurrence must not be duplicated; independent series must each get one")
        february.status = .cancelled
        try RecurrenceService.insertNextOccurrenceIfNeeded(after: first, in: context, calendar: calendar)
        try check(context.fetch(FetchDescriptor<Transaction>()).count == 4, "Cancelled occurrence must not be recreated")
        february.status = .paid
        try RecurrenceService.insertNextOccurrenceIfNeeded(after: february, in: context, calendar: calendar)
        try check(context.fetch(FetchDescriptor<Transaction>()).first { $0.recurrenceSeriesID == firstID && $0.dueDate == date(2024,3,31) } != nil, "Anchor returns to March 31")
        let legacy = Transaction(title: "Same bill", amount: 100, type: .expense, dueDate: date(2024,1,31), recurrence: .monthly)
        context.insert(legacy)
        let later = RecurrenceService.futureOccurrences(matching: .init(transaction: legacy), in: rows)
        try check(later.isEmpty, "Legacy template must not capture a separate explicit series for edit/delete")
        try RecurrenceService.insertNextOccurrenceIfNeeded(after: legacy, in: context, calendar: calendar)
        try check(legacy.recurrenceSeriesID != firstID && legacy.recurrenceSeriesID != secondID, "Legacy creation must not join another explicit series")
        for (rule, interval) in [(RecurrenceRule.monthly,1),(.quarterly,3),(.halfYearly,6),(.yearly,12),(.everyNMonths,5),(.custom,5)] {
            let item = Transaction(title: "Boundary", amount: 1, type: .income, dueDate: date(2024,2,29), recurrence: rule, recurrenceIntervalMonths: interval, recurrenceAnchorDay: 29)
            let actual = RecurrenceService.nextDueDate(after: item.dueDate, for: item, calendar: calendar)
            let expected = RecurrenceService.nextDueDate(after: item.dueDate, anchorDay: 29, monthInterval: interval, calendar: calendar)
            try check(actual == expected && actual! > item.dueDate, "Rule interval and leap-year boundary: " + rule.rawValue)
        }

        // Real duplicate definition rows previously produced an un-restorable native backup.
        let old = CategoryDefinition(id: "audit-category", name: "Old", excludesFromSavingsTips: false, updatedAt: date(2024,1,1))
        let latest = CategoryDefinition(id: "audit-category", name: "Latest", excludesFromSavingsTips: true, updatedAt: date(2024,2,1))
        let backup = try ExportService.makeJSONBackup(transactions: [], categoryDefinitions: [old,latest])
        defer { try? FileManager.default.removeItem(at: backup) }
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: backup)) as! [String: Any]
        let categories = json["categories"] as! [[String: Any]]
        try check(categories.filter { $0["id"] as? String == "audit-category" }.count == 1, "Export one canonical category per logical ID")
        let target = try BackupRestoreVerification.store(root.appendingPathComponent("categories.store"))
        let targetContext = ModelContext(target)
        targetContext.insert(CategoryDefinition(id: "audit-category", name: "Other device old", updatedAt: date(2025,1,1)))
        targetContext.insert(CategoryDefinition(id: "audit-category", name: "Other device new", updatedAt: date(2025,2,1)))
        try targetContext.save()
        let suite = "SaldoPilot.FinalAudit." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        _ = try ImportService.importFile(at: backup, mode: .replaceExisting, modelContext: targetContext, userDefaults: defaults)
        let restored = try ModelContext(target).fetch(FetchDescriptor<CategoryDefinition>()).filter { $0.id == "audit-category" }
        try check(restored.count == 2 && restored.allSatisfy { $0.name == "Latest" && $0.excludesFromSavingsTips == true }, "Restore all physical duplicates consistently without deleting them")
        _ = try ImportService.importFile(at: backup, mode: .merge, modelContext: targetContext, userDefaults: defaults)
        try check(ModelContext(target).fetch(FetchDescriptor<CategoryDefinition>()).filter { $0.id == "audit-category" }.count == 2, "Repeated merge must not add category duplicates")

        var sync = CloudSyncState()
        let success = date(2026,11,16)
        sync.receive(id: UUID(), operation: .upload, endedAt: success, succeeded: true, failure: nil)
        sync.receive(id: UUID(), operation: .upload, endedAt: success.addingTimeInterval(-60), succeeded: false, failure: nil)
        try check(sync.latestFailure == nil, "Late old failure must not override a newer success")
        sync.receive(id: UUID(), operation: .download, endedAt: success.addingTimeInterval(-60), succeeded: false, failure: nil)
        try check(sync.latestFailure != nil, "Upload success must not hide independent download failure")
    }
}
