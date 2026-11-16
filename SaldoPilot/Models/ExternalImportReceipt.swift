import Foundation
import SwiftData

/// Import provenance only; no transaction is removed when a receipt is changed.
@Model
final class ExternalImportReceipt {
    var sourceID: String = ""
    var transactionID: UUID = UUID()
    var fingerprint: String = ""
    var exportedAt: Date = Date.distantPast
    init(sourceID: String, transactionID: UUID, fingerprint: String, exportedAt: Date) {
        self.sourceID = sourceID; self.transactionID = transactionID
        self.fingerprint = fingerprint; self.exportedAt = exportedAt
    }
}

struct ExternalImportReceiptRecord: Codable {
    let sourceID: String
    let transactionID: UUID
    let fingerprint: String
    let exportedAt: Date
    init(_ receipt: ExternalImportReceipt) {
        sourceID = receipt.sourceID; transactionID = receipt.transactionID
        fingerprint = receipt.fingerprint; exportedAt = receipt.exportedAt
    }
    var isValid: Bool {
        UUID(uuidString: sourceID) != nil && fingerprint.count == 64
            && fingerprint.allSatisfy { $0.isHexDigit } && exportedAt.timeIntervalSinceReferenceDate.isFinite
    }
}
