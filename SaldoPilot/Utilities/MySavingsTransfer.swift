import Foundation
import SwiftData
import CryptoKit

struct MySavingsTransferConflict: Identifiable, Equatable {
    let id: UUID
    let title: String
    let reason: String
}
struct MySavingsTransferOutcome {
    var updated = 0
    var linked = 0
    var olderSkipped = 0
    var conflicts: [MySavingsTransferConflict] = []
}
@MainActor
enum MySavingsTransfer {
    static func fingerprint(_ t: Transaction) -> String {
        var input = t.amount, rounded = Decimal.zero
        NSDecimalRound(&rounded, &input, 2, .plain)
        func date(_ d: Date?) -> String { d.map { String($0.timeIntervalSinceReferenceDate) } ?? "nil" }
        let parts = [t.title, NSDecimalNumber(decimal: rounded).stringValue, t.type.rawValue,
                     date(t.dueDate), date(t.paidDate), t.status.rawValue, t.categoryID,
                     t.recurrence.rawValue, t.recurrenceIntervalMonths.map(String.init) ?? "nil",
                     t.recurrenceSeriesID?.uuidString ?? "nil", t.recurrenceAnchorDay.map(String.init) ?? "nil",
                     t.notes, String(t.isCompleted), String(t.isArchived)]
        return SHA256.hash(data: Data(parts.map { String($0.utf8.count) + ":" + $0 }.joined().utf8)).map { String(format: "%02x", $0) }.joined()
    }
    static func stamp(_ t: Transaction, exportedAt: Date, context: ModelContext) {
        context.insert(ExternalImportReceipt(sourceID: t.id.uuidString, transactionID: t.id,
                                            fingerprint: fingerprint(t), exportedAt: exportedAt))
    }
    static func reconcile(_ source: Transaction, with local: Transaction, receipts: [ExternalImportReceipt], exportedAt: Date, context: ModelContext, outcome: inout MySavingsTransferOutcome) {
        let matches = receipts.filter { $0.sourceID == source.id.uuidString }
        func conflict(_ reason: String) { outcome.conflicts.append(.init(id: source.id, title: source.title, reason: reason)) }
        guard matches.count <= 1 else { conflict("Flere importreferanser. Posten er beholdt uendret."); return }
        let incoming = fingerprint(source)
        guard let receipt = matches.first else {
            guard fingerprint(local) == incoming else {
                conflict("Tidligere import mangler sammenligningsgrunnlag. Importer den opprinnelige filen først, eller kontroller posten manuelt."); return
            }
            stamp(local, exportedAt: exportedAt, context: context); outcome.linked += 1; return
        }
        guard receipt.transactionID == local.id else { conflict("Importreferansen stemmer ikke. Posten er beholdt uendret."); return }
        guard exportedAt >= receipt.exportedAt else { outcome.olderSkipped += 1; return }
        if receipt.fingerprint == incoming { receipt.exportedAt = exportedAt; return }
        guard fingerprint(local) == receipt.fingerprint else {
            conflict("Posten er endret lokalt. Ingen verdier er overskrevet."); return
        }
        local.title = source.title; local.amount = source.amount; local.type = source.type
        local.dueDate = source.dueDate; local.paidDate = source.paidDate; local.status = source.status
        local.category = source.category; local.customCategoryID = source.customCategoryID
        local.recurrence = source.recurrence; local.recurrenceIntervalMonths = source.recurrenceIntervalMonths
        local.recurrenceSeriesID = source.recurrenceSeriesID; local.recurrenceAnchorDay = source.recurrenceAnchorDay
        local.notes = source.notes; local.isCompleted = source.isCompleted; local.isArchived = source.isArchived
        local.updatedAt = .now
        receipt.fingerprint = fingerprint(local); receipt.exportedAt = exportedAt; outcome.updated += 1
    }
}
