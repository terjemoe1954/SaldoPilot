import Foundation
import SwiftData
enum AppLaunchConfiguration { static let usesIsolatedTestStore = true }
@main struct Audit {
 @MainActor static func main() throws {
  let url = URL(fileURLWithPath:CommandLine.arguments[1])
  let root = URL(fileURLWithPath:CommandLine.arguments[2]); try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
  let migrationURL = root.appendingPathComponent("migration.store")
  do {
   let oldSchema = Schema(SaldoPilotSchemaV5.models)
   let old = try ModelContainer(for:oldSchema,configurations:[ModelConfiguration(schema:oldSchema,url:migrationURL,cloudKitDatabase:.none)])
   let c = ModelContext(old)
   c.insert(Transaction(title:"Preserve V5",amount:1249.50,type:.expense,dueDate:Date(timeIntervalSince1970:1700000000),recurrence:.yearly))
   c.insert(CategoryDefinition(id:"preserve-category",name:"Preserve category"))
   c.insert(Budget(category:.other,monthStart:Date(timeIntervalSince1970:1700000000),amount:999))
   try c.save()
  }
  let newSchema = Schema(SaldoPilotSchemaV6.models)
  let migrated = try ModelContainer(for:newSchema,migrationPlan:SaldoPilotMigrationPlan.self,configurations:[ModelConfiguration(schema:newSchema,url:migrationURL,cloudKitDatabase:.none)])
  let migratedRows = try ModelContext(migrated).fetch(FetchDescriptor<Transaction>())
  let migratedBudgets = try ModelContext(migrated).fetch(FetchDescriptor<Budget>())
  let migratedCategories = try ModelContext(migrated).fetch(FetchDescriptor<CategoryDefinition>())
  precondition(migratedRows.count == 1 && migratedRows[0].amount == Decimal(string:"1249.50")! && migratedRows[0].recurrence == .yearly)
  precondition(migratedBudgets.count == 1 && migratedBudgets[0].amount == 999 && migratedCategories.count == 1)
  print("Saldopilot V5 to V6 migration preserved transactions, recurrence, category and budget")
  let container = try BackupRestoreVerification.store(root.appendingPathComponent("test.store"))
  let context = ModelContext(container)
  let data = try Data(contentsOf:url)
  let first = try ImportService.importFile(at:url,mode:.merge,modelContext:context)
  let repeated = try ImportService.importFile(at:url,mode:.merge,modelContext:context)
  precondition(first.transactionsCreated > 0 && repeated.transactionsCreated == 0 && repeated.sourceConflicts.isEmpty)
  var object = try JSONSerialization.jsonObject(with:data) as! [String:Any]
  var rows = object["transactions"] as! [[String:Any]]
  let id = UUID(uuidString:rows[0]["id"] as! String)!
  rows[0]["amount"] = "12345.67"; object["transactions"] = rows; object["exportedAt"] = "2026-12-01T12:00:00Z"
  let changed = root.appendingPathComponent("changed.json");try JSONSerialization.data(withJSONObject:object).write(to:changed)
  let update = try ImportService.importFile(at:changed,mode:.merge,modelContext:context)
  precondition(update.sourceUpdated == 1 && update.sourceConflicts.isEmpty && update.transactionsCreated == 0)
  let fresh = ModelContext(container); let local = try fresh.fetch(FetchDescriptor<Transaction>()).first { $0.id == id }!
  precondition(local.amount == Decimal(string:"12345.67")!);local.amount = 777;try fresh.save()
  rows[0]["amount"] = "54321";object["transactions"] = rows;object["exportedAt"] = "2026-12-02T12:00:00Z"
  try JSONSerialization.data(withJSONObject:object).write(to:changed)
  let conflict = try ImportService.importFile(at:changed,mode:.merge,modelContext:context)
  precondition(conflict.sourceConflicts.count == 1 && conflict.transactionsCreated == 0)
  let older = try ImportService.importFile(at:url,mode:.merge,modelContext:context)
  precondition(older.sourceOlderSkipped == first.transactionsCreated)
  let snapshotContext = ModelContext(container)
  let backup = try ExportService.makeJSONBackup(transactions:snapshotContext.fetch(FetchDescriptor<Transaction>()),importReceipts:snapshotContext.fetch(FetchDescriptor<ExternalImportReceipt>()))
  let restored = try BackupRestoreVerification.store(root.appendingPathComponent("restored.store"))
  _ = try ImportService.importFile(at:backup,mode:.replaceExisting,modelContext:ModelContext(restored))
  let afterRestore = try ImportService.importFile(at:changed,mode:.merge,modelContext:ModelContext(restored))
  precondition(afterRestore.sourceConflicts.count == 1 && afterRestore.transactionsCreated == 0)
  print("Saldopilot passed:",first.transactionsCreated,"rows; repeat, update, local conflict, older file, backup provenance")
 }
}
