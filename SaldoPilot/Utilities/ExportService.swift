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
        categoryDefinitions: [CategoryDefinition] = [],
        settings: BackupAppSettings? = nil,
        importReceipts: [ExternalImportReceipt] = [],
        savingsGoals: [SavingsGoal] = []
    ) throws -> URL {
        let definitions = CategoryOption.preferredDefinitions(categoryDefinitions).values.sorted { $0.id < $1.id }
        let payload = ExportPayload(
            formatVersion: 7,
            exportedAt: .now,
            categories: CategoryKind.allCases.filter { kind in !definitions.contains { $0.id == kind.rawValue } }.map(ExportCategory.init) + definitions.map(ExportCategory.init),
            transactions: transactions.map(ExportTransaction.init),
            budgets: budgets.map(ExportBudget.init),
            settings: settings,
            importReceipts: importReceipts.map(ExternalImportReceiptRecord.init),
            savingsGoals: SavingsGoalSelection.preferred(savingsGoals).map(SavingsGoalRecord.init)
        )

        let encoder = JSONEncoder()
        // Keep readable ISO dates for older apps; V5 additionally keeps lossless timestamps.
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        let data = try encoder.encode(payload)
        let url = exportURL(prefix: "SaldoPilot-Backup", extension: "json")
        try writeExportData(data, to: url)
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
                transaction.categoryID,
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
        try writeExportData(data, to: url)
        return url
    }

    private static func exportURL(prefix: String, extension fileExtension: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(fileTimestamp())-\(UUID().uuidString).\(fileExtension)")
    }

    private static func writeExportData(_ data: Data, to url: URL) throws {
        guard !FileManager.default.fileExists(atPath: url.path) else {
            throw CocoaError(
                .fileWriteFileExists,
                userInfo: [NSFilePathErrorKey: url.path]
            )
        }

        // Foundation does not support combining atomic writes with withoutOverwriting.
        try data.write(to: url, options: .atomic)
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
    let importReceipts: [ExternalImportReceiptRecord]
    let savingsGoals: [SavingsGoalRecord]
}

private struct ExportBudget: Encodable {
    let preciseDates: [String: Double]
    let id: UUID
    let category: String
    let legacyCategory: String
    let monthStart: Date
    let amount: String
    let createdAt: Date
    let updatedAt: Date

    init(budget: Budget) {
        preciseDates = ["monthStart": budget.monthStart.timeIntervalSinceReferenceDate,
                        "createdAt": budget.createdAt.timeIntervalSinceReferenceDate,
                        "updatedAt": budget.updatedAt.timeIntervalSinceReferenceDate]
        id = budget.id
        category = budget.categoryID
        legacyCategory = budget.category.rawValue
        monthStart = budget.monthStart
        amount = budget.amount.description
        createdAt = budget.createdAt
        updatedAt = budget.updatedAt
    }
}

private struct ExportCategory: Encodable {
    let preciseDates: [String: Double]
    let id: String
    let name: String
    let icon: String
    let colorIdentifier: String
    let legacyKindRawValue: String?
    let excludesFromSavingsTips: Bool?
    let isUserDefined: Bool
    let isHidden: Bool
    let createdAt: Date?
    let updatedAt: Date?

    init(category: CategoryKind) {
        preciseDates = [:]
        id = category.rawValue
        name = String(localized: category.title)
        icon = category.systemImage
        colorIdentifier = category.colorName
        legacyKindRawValue = category.rawValue
        excludesFromSavingsTips = nil
        isUserDefined = false
        isHidden = false
        createdAt = nil
        updatedAt = nil
    }

    init(definition: CategoryDefinition) {
        preciseDates = ["createdAt": definition.createdAt.timeIntervalSinceReferenceDate,
                        "updatedAt": definition.updatedAt.timeIntervalSinceReferenceDate]
        id = definition.id
        name = definition.name
        icon = definition.systemImage
        colorIdentifier = definition.colorName
        legacyKindRawValue = definition.legacyKindRawValue
        excludesFromSavingsTips = definition.excludesFromSavingsTips
        isUserDefined = true
        isHidden = definition.isHidden
        createdAt = definition.createdAt
        updatedAt = definition.updatedAt
    }
}

private struct ExportTransaction: Encodable {
    let preciseDates: [String: Double]
    let id: UUID
    let title: String
    let amount: String
    let type: String
    let dueDate: Date
    let paidDate: Date?
    let status: String
    let category: String
    let legacyCategory: String
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
        var dates = ["dueDate": transaction.dueDate.timeIntervalSinceReferenceDate,
                     "createdAt": transaction.createdAt.timeIntervalSinceReferenceDate,
                     "updatedAt": transaction.updatedAt.timeIntervalSinceReferenceDate]
        if let paidDate = transaction.paidDate { dates["paidDate"] = paidDate.timeIntervalSinceReferenceDate }
        preciseDates = dates
        id = transaction.id
        title = transaction.title
        amount = transaction.amount.description
        type = transaction.type.rawValue
        dueDate = transaction.dueDate
        paidDate = transaction.paidDate
        status = transaction.status.rawValue
        category = transaction.categoryID
        legacyCategory = transaction.category.rawValue
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
