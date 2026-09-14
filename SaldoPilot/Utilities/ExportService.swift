//
//  ExportService.swift
//  SaldoPilot
//
//  Created by Terje Moe on 13/09/2026.
//

import Foundation

@MainActor
enum ExportService {
    static func makeJSONBackup(transactions: [Transaction]) throws -> URL {
        let payload = ExportPayload(
            exportedAt: .now,
            categories: CategoryKind.allCases.map(ExportCategory.init),
            transactions: transactions.map(ExportTransaction.init)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        let data = try encoder.encode(payload)
        let url = exportURL(prefix: "SaldoPilot-Backup", extension: "json")
        try data.write(to: url, options: .atomic)
        return url
    }

    static func makeCSVExport(transactions: [Transaction]) throws -> URL {
        let headers = [
            "title",
            "amount",
            "type",
            "dueDate",
            "paidDate",
            "status",
            "category",
            "recurrence",
            "recurrenceIntervalMonths",
            "notes"
        ]

        let rows = transactions.map { transaction in
            [
                transaction.title,
                transaction.amount.description,
                transaction.type.rawValue,
                isoString(from: transaction.dueDate),
                transaction.paidDate.map(isoString) ?? "",
                transaction.status.rawValue,
                transaction.category.rawValue,
                transaction.recurrence.rawValue,
                transaction.recurrenceIntervalMonths?.formatted() ?? "",
                transaction.notes
            ]
            .map(csvEscaped)
            .joined(separator: ",")
        }

        let csv = ([headers.joined(separator: ",")] + rows).joined(separator: "\n")
        let url = exportURL(prefix: "SaldoPilot-Transactions", extension: "csv")
        try Data(csv.utf8).write(to: url, options: .atomic)
        return url
    }

    private static func exportURL(prefix: String, extension fileExtension: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(fileTimestamp()).\(fileExtension)")
    }

    private static func isoString(from date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private static func fileTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: .now)
    }

    private static func csvEscaped(_ value: String) -> String {
        let escapedValue = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escapedValue)\""
    }
}

private struct ExportPayload: Encodable {
    let exportedAt: Date
    let categories: [ExportCategory]
    let transactions: [ExportTransaction]
}

private struct ExportCategory: Encodable {
    let id: String
    let name: String
    let icon: String

    init(category: CategoryKind) {
        id = category.rawValue
        name = String(localized: category.title)
        icon = category.systemImage
    }
}

private struct ExportTransaction: Encodable {
    let title: String
    let amount: String
    let type: String
    let dueDate: Date
    let paidDate: Date?
    let status: String
    let category: String
    let recurrence: String
    let recurrenceIntervalMonths: String?
    let notes: String

    init(transaction: Transaction) {
        title = transaction.title
        amount = transaction.amount.description
        type = transaction.type.rawValue
        dueDate = transaction.dueDate
        paidDate = transaction.paidDate
        status = transaction.status.rawValue
        category = transaction.category.rawValue
        recurrence = transaction.recurrence.rawValue
        recurrenceIntervalMonths = transaction.recurrenceIntervalMonths?.formatted()
        notes = transaction.notes
    }
}
