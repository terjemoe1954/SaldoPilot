//
//  ExportService.swift
//  SaldoPilot
//
//  Created by Terje Moe on 13/09/2026.
//

import Foundation

@MainActor
enum ExportService {
    static func makeJSONBackup(
        transactions: [Transaction],
        budgets: [Budget] = [],
        settings: BackupAppSettings? = nil
    ) throws -> URL {
        let payload = ExportPayload(
            formatVersion: 4,
            exportedAt: .now,
            categories: CategoryKind.allCases.map(ExportCategory.init),
            transactions: transactions.map(ExportTransaction.init),
            budgets: budgets.map(ExportBudget.init),
            settings: settings
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        let data = try encoder.encode(payload)
        let url = exportURL(prefix: "SaldoPilot-Backup", extension: "json")
        try data.write(to: url, options: [.atomic, .withoutOverwriting])
        return url
    }

    static func makeCSVExport(transactions: [Transaction]) throws -> URL {
        let headers = [
            "id",
            "title",
            "amount",
            "type",
            "dueDate",
            "paidDate",
            "status",
            "category",
            "recurrence",
            "recurrenceIntervalMonths",
            "notes",
            "createdAt",
            "updatedAt",
            "isCompleted",
            "isArchived"
        ]

        let rows = transactions.map { transaction in
            [
                transaction.id.uuidString,
                transaction.title,
                transaction.amount.description,
                transaction.type.rawValue,
                isoString(from: transaction.dueDate),
                transaction.paidDate.map(isoString) ?? "",
                transaction.status.rawValue,
                transaction.category.rawValue,
                transaction.recurrence.rawValue,
                transaction.recurrenceIntervalMonths?.formatted() ?? "",
                transaction.notes,
                isoString(from: transaction.createdAt),
                isoString(from: transaction.updatedAt),
                transaction.isCompleted.description,
                transaction.isArchived.description
            ]
            .map(csvEscaped)
            .joined(separator: ",")
        }

        let csv = ([headers.joined(separator: ",")] + rows).joined(separator: "\n")
        let url = exportURL(prefix: "SaldoPilot-Transactions", extension: "csv")
        var data = Data([0xEF, 0xBB, 0xBF])
        data.append(contentsOf: csv.utf8)
        try data.write(to: url, options: [.atomic, .withoutOverwriting])
        return url
    }

    private static func exportURL(prefix: String, extension fileExtension: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(fileTimestamp())-\(UUID().uuidString).\(fileExtension)")
    }

    private static func isoString(from date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private static func fileTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        return formatter.string(from: .now)
    }

    private static func csvEscaped(_ value: String) -> String {
        let safeValue: String
        let firstMeaningfulCharacter = value.drop(while: { $0 == " " }).first
        if let firstMeaningfulCharacter, "=+-@\t\r".contains(firstMeaningfulCharacter) {
            safeValue = "'" + value
        } else {
            safeValue = value
        }
        let escapedValue = safeValue.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escapedValue)\""
    }
}

private struct ExportPayload: Encodable {
    let formatVersion: Int
    let exportedAt: Date
    let categories: [ExportCategory]
    let transactions: [ExportTransaction]
    let budgets: [ExportBudget]
    let settings: BackupAppSettings?
}

private struct ExportBudget: Encodable {
    let id: UUID
    let category: String
    let monthStart: Date
    let amount: String
    let createdAt: Date
    let updatedAt: Date

    init(budget: Budget) {
        id = budget.id
        category = budget.category.rawValue
        monthStart = budget.monthStart
        amount = budget.amount.description
        createdAt = budget.createdAt
        updatedAt = budget.updatedAt
    }
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
    let id: UUID
    let title: String
    let amount: String
    let type: String
    let dueDate: Date
    let paidDate: Date?
    let status: String
    let category: String
    let recurrence: String
    let recurrenceIntervalMonths: String?
    let recurrenceSeriesID: UUID?
    let recurrenceAnchorDay: Int?
    let notes: String
    let createdAt: Date
    let updatedAt: Date
    let isCompleted: Bool
    let isArchived: Bool

    init(transaction: Transaction) {
        id = transaction.id
        title = transaction.title
        amount = transaction.amount.description
        type = transaction.type.rawValue
        dueDate = transaction.dueDate
        paidDate = transaction.paidDate
        status = transaction.status.rawValue
        category = transaction.category.rawValue
        recurrence = transaction.recurrence.rawValue
        recurrenceIntervalMonths = transaction.recurrenceIntervalMonths?.formatted()
        recurrenceSeriesID = transaction.recurrenceSeriesID
        recurrenceAnchorDay = transaction.recurrenceAnchorDay
        notes = transaction.notes
        createdAt = transaction.createdAt
        updatedAt = transaction.updatedAt
        isCompleted = transaction.isCompleted
        isArchived = transaction.isArchived
    }
}
