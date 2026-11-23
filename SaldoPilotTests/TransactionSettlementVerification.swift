import Foundation
import SwiftData
#if canImport(SaldoPilot)
@testable import SaldoPilot
#endif

@MainActor
enum TransactionSettlementVerification {
    enum Failure: Error { case checkFailed }
    static func check(_ result: Bool) throws { if !result { throw Failure.checkFailed } }
    static func run() throws {
        let schema = Schema(SaldoPilotSchemaV7.models)
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)])
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let due = Date(timeIntervalSince1970: 1795089600)
        let chosen = due.addingTimeInterval(-2 * 86400)
        let bill = Transaction(title: "Payment test", amount: 1249.50, type: .expense, dueDate: due, recurrence: .monthly, recurrenceIntervalMonths: 1)
        context.insert(bill)
        try context.save()
        try check(TransactionSettlementService.suggestedDate(for: bill) == due)
        try check(!bill.isSettled && bill.paidDate == nil)
        try TransactionSettlementService.save(bill, paymentDate: chosen, in: context)
        try check(bill.isCompleted && bill.status == .paid && bill.paidDate == chosen && bill.dueDate == due && bill.amount == Decimal(string: "1249.50"))
        let afterFirst = try context.fetch(FetchDescriptor<Transaction>())
        try check(afterFirst.count == 2 && afterFirst.filter { !$0.isSettled }.count == 1)
        let corrected = chosen.addingTimeInterval(86400)
        try TransactionSettlementService.save(bill, paymentDate: corrected, in: context)
        try TransactionSettlementService.save(bill, paymentDate: corrected, in: context)
        let afterRepeat = try context.fetch(FetchDescriptor<Transaction>())
        try check(afterRepeat.count == 2 && bill.paidDate == corrected && bill.dueDate == due)
        try check(TransactionSettlementService.suggestedDate(for: bill) == corrected)
        let income = Transaction(title: "Income test", amount: 32000, type: .income, dueDate: due)
        context.insert(income); try context.save()
        try TransactionSettlementService.save(income, paymentDate: chosen, in: context)
        try check(income.status == .received && income.isCompleted && income.paidDate == chosen)
        let cancelled = Transaction(title: "Cancelled test", amount: 99, type: .expense, dueDate: due, status: .cancelled)
        context.insert(cancelled); try context.save()
        do {
            try TransactionSettlementService.save(cancelled, paymentDate: chosen, in: context)
            throw Failure.checkFailed
        } catch TransactionSettlementService.Failure.unavailable {}
        try check(cancelled.status == .cancelled && cancelled.paidDate == nil)
        let reloaded = try ModelContext(container).fetch(FetchDescriptor<Transaction>())
        try check(reloaded.first { $0.id == bill.id }?.paidDate == corrected)
    }
}
