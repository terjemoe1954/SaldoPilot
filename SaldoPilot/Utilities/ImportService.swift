//
//  ImportService.swift
//  SaldoPilot
//
//  Created by Terje Moe on 13/09/2026.
//

import Foundation
import SwiftData

struct ImportSummary: Equatable {
    let categorizedRows: Int
    let transactionsCreated: Int
    let replacedTransactions: Int
    let budgetsCreated: Int
    let replacedBudgets: Int
    let settingsRestored: Bool
    let skippedRows: Int
    var goalsCreated: Int = 0
    var sourceUpdated: Int = 0
    var sourceLinked: Int = 0
    var sourceOlderSkipped: Int = 0
    var sourceConflicts: [MySavingsTransferConflict] = []

    var message: String {
        let transactionMessage = if replacedTransactions > 0 {
            String(localized: "Imported \(transactionsCreated) transactions. Replaced \(replacedTransactions) existing transactions. Matched categories for \(categorizedRows) rows. Skipped \(skippedRows) rows.")
        } else {
            String(localized: "Imported \(transactionsCreated) transactions. Matched categories for \(categorizedRows) rows. Skipped \(skippedRows) rows.")
        }
        var messages = [transactionMessage]
        if goalsCreated > 0 { messages.append(String(localized: "Restored \(goalsCreated) savings goals.")) }
        if budgetsCreated > 0 || replacedBudgets > 0 {
            messages.append(String(localized: "Imported \(budgetsCreated) budgets. Replaced \(replacedBudgets) existing budgets."))
        }
        if sourceUpdated > 0 { messages.append(String(localized: "Updated \(sourceUpdated) unchanged source transactions.")) }
        if sourceLinked > 0 { messages.append("Knyttet \(sourceLinked) tidligere importerte poster til MySavings.") }
        if sourceOlderSkipped > 0 { messages.append("Beholdt \(sourceOlderSkipped) poster fordi filen er eldre enn siste import.") }
        if !sourceConflicts.isEmpty { messages.append(String(localized: "Kept \(sourceConflicts.count) transactions for conflict review.")) }
        if settingsRestored {
            messages.append(String(localized: "Restored app settings."))
        }
        return messages.joined(separator: " ")
    }
}

enum ImportMode {
    case merge
    case replaceExisting
}

@MainActor
enum ImportService {
    static func importFile(
        at url: URL,
        mode: ImportMode = .merge,
        modelContext: ModelContext,
        userDefaults: UserDefaults = .standard,
        allowNewMySavingsRecordsAlongsideUntracked: Bool = false
    ) throws -> ImportSummary {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        let fileExtension = url.pathExtension.lowercased()

        let importResult: PreparedImportResult
        if fileExtension == "csv" {
            let text = String(decoding: data, as: UTF8.self)
            importResult = try importCSV(text)
        } else {
            importResult = try importJSON(data)
        }

        if mode == .replaceExisting, importResult.skippedRows > 0 { throw BackupImportError.invalidBackup }
        if fileExtension == "csv", importResult.transactions.isEmpty { throw BackupImportError.invalidBackup }

        // Decode and validate everything before making any changes. Use a dedicated context
        // so a failed restore cannot roll back unrelated edits in the UI context.
        let context = ModelContext(modelContext.container)
        context.autosaveEnabled = false
        let existingTransactions = try context.fetch(FetchDescriptor<Transaction>())
        let existingBudgets = try context.fetch(FetchDescriptor<Budget>())
        let existingDefinitions = try context.fetch(FetchDescriptor<CategoryDefinition>())
        let existingReceipts = try context.fetch(FetchDescriptor<ExternalImportReceipt>())
        let existingGoals = try context.fetch(FetchDescriptor<SavingsGoal>())
        var goalsCreated = 0
        if mode == .replaceExisting, importResult.includesSavingsGoals {
            existingGoals.forEach { context.delete($0) }
        }
        var goalIDs = Set(mode == .replaceExisting && importResult.includesSavingsGoals ? [] : existingGoals.map(\.id))
        for record in importResult.savingsGoals {
            guard goalIDs.insert(record.id).inserted else { continue }
            context.insert(record.makeGoal()); goalsCreated += 1
        }
        var transfer = MySavingsTransferOutcome()
        var transactionIDs = Set(existingTransactions.map(\.id))
        var budgetIDs = Set(existingBudgets.map(\.id))
        var definitionsByID = CategoryOption.preferredDefinitions(existingDefinitions)
        var replacedTransactions = 0
        var replacedBudgets = 0
        var transactionsCreated = 0
        var budgetsCreated = 0
        var skippedRows = importResult.skippedRows

        if mode == .replaceExisting {
            existingReceipts.forEach { context.delete($0) }
            existingTransactions.forEach { context.delete($0) }
            replacedTransactions = existingTransactions.count
            transactionIDs.removeAll()
            if importResult.includesBudgets {
                existingBudgets.forEach { context.delete($0) }
                replacedBudgets = existingBudgets.count
                budgetIDs.removeAll()
            }
        }

        for transaction in importResult.transactions {
            if transactionIDs.contains(transaction.id) {
                if mode == .merge, let exportedAt = importResult.mySavingsExportedAt,
                   let existing = existingTransactions.first(where: { $0.id == transaction.id }) {
                    MySavingsTransfer.reconcile(transaction, with: existing, receipts: existingReceipts,
                                               exportedAt: exportedAt, context: context, outcome: &transfer)
                } else { skippedRows += 1 }
                continue
            }
            if mode == .merge, importResult.mySavingsExportedAt != nil,
               !allowNewMySavingsRecordsAlongsideUntracked,
               existingTransactions.contains(where: { old in !existingReceipts.contains(where: { $0.transactionID == old.id }) }) {
                transfer.conflicts.append(.init(id: transaction.id, title: transaction.title,
                    reason: "Kan være en eldre import uten kilde-ID. Importer originalfilen først. Tillat bare nye poster etter manuell kontroll."))
                continue
            }
            transactionIDs.insert(transaction.id)
            context.insert(transaction)
            transactionsCreated += 1
            if let exportedAt = importResult.mySavingsExportedAt {
                MySavingsTransfer.stamp(transaction, exportedAt: exportedAt, context: context)
            }
        }
        for record in importResult.importReceipts where transactionIDs.contains(record.transactionID) {
            if mode == .merge, existingReceipts.contains(where: { $0.sourceID == record.sourceID }) { continue }
            context.insert(ExternalImportReceipt(sourceID: record.sourceID, transactionID: record.transactionID, fingerprint: record.fingerprint, exportedAt: record.exportedAt))
        }
        for budget in importResult.budgets {
            guard budgetIDs.insert(budget.id).inserted else { skippedRows += 1; continue }
            context.insert(budget)
            budgetsCreated += 1
        }
        for definition in importResult.categoryDefinitions {
            if definitionsByID[definition.id] != nil {
                if mode == .replaceExisting {
                    for existing in existingDefinitions.filter({ $0.id == definition.id }) {
                        existing.name = definition.name
                        existing.systemImage = definition.systemImage
                        existing.colorName = definition.colorName
                        existing.legacyKindRawValue = definition.legacyKindRawValue
                        existing.isHidden = definition.isHidden
                        existing.excludesFromSavingsTips = definition.excludesFromSavingsTips
                        existing.createdAt = definition.createdAt
                        existing.updatedAt = definition.updatedAt
                    }
                }
            } else {
                context.insert(definition)
                definitionsByID[definition.id] = definition
            }
        }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        // A MySavings transfer must not reset destination preferences on each import.
        if importResult.mySavingsExportedAt == nil { importResult.settings?.apply(to: userDefaults) }
        return ImportSummary(
            categorizedRows: importResult.categorizedRows,
            transactionsCreated: transactionsCreated,
            replacedTransactions: replacedTransactions,
            budgetsCreated: budgetsCreated,
            replacedBudgets: replacedBudgets,
            settingsRestored: importResult.settings != nil && importResult.mySavingsExportedAt == nil,
            skippedRows: skippedRows,
            goalsCreated: goalsCreated,
            sourceUpdated: transfer.updated,
            sourceLinked: transfer.linked,
            sourceOlderSkipped: transfer.olderSkipped,
            sourceConflicts: transfer.conflicts
        )
    }

    private static func importJSON(_ data: Data) throws -> PreparedImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let payload = try decoder.decode(ImportPayload.self, from: data)
        if payload.isMySavings && payload.exportedAt == nil { throw BackupImportError.invalidBackup }
        let categoryLookup = CategoryImportLookup(categories: payload.categories ?? [])
        if payload.formatVersion != nil {
            let categoryIDs = Set(CategoryKind.allCases.map(\.rawValue) + (payload.categories ?? []).compactMap(\.id))
            for row in payload.transactions ?? [] {
                if (payload.formatVersion ?? 0) >= 5 {
                    guard row.legacyCategory != nil,
                          ["dueDate", "createdAt", "updatedAt"].allSatisfy({ row.preciseDates?[$0] != nil }),
                          row.paidDate == nil || row.preciseDates?["paidDate"] != nil else { throw BackupImportError.invalidBackup }
                }
                guard row.id.flatMap(UUID.init(uuidString:)) != nil,
                      row.type.flatMap(TransactionType.init(rawValue:)) != nil,
                      row.status.flatMap(TransactionStatus.init(rawValue:)) != nil,
                      row.recurrence.flatMap(RecurrenceRule.init(rawValue:)) != nil,
                      row.category.map(categoryIDs.contains) == true,
                      Date(importValue: row.createdAt) != nil, Date(importValue: row.updatedAt) != nil,
                      row.isCompleted.flatMap(Bool.init(importValue:)) != nil,
                      row.isArchived.flatMap(Bool.init(importValue:)) != nil else { throw BackupImportError.invalidBackup }
                if let value = row.paidDate, Date(importValue: value) == nil { throw BackupImportError.invalidBackup }
                if let value = row.legacyCategory, CategoryKind(rawValue: value) == nil { throw BackupImportError.invalidBackup }
                if let value = row.recurrenceSeriesID, UUID(uuidString: value) == nil { throw BackupImportError.invalidBackup }
                if let value = row.recurrenceAnchorDay, !(Int(value).map { (1...31).contains($0) } ?? false) { throw BackupImportError.invalidBackup }
                if let value = row.recurrenceIntervalMonths, !(Int(value).map { $0 > 0 } ?? false) { throw BackupImportError.invalidBackup }
            }
            for row in payload.budgets {
                if (payload.formatVersion ?? 0) >= 5 {
                    guard row.legacyCategory != nil,
                          ["monthStart", "createdAt", "updatedAt"].allSatisfy({ row.preciseDates?[$0] != nil }) else { throw BackupImportError.invalidBackup }
                }
                guard row.category.map(categoryIDs.contains) == true,
                      Date(importValue: row.createdAt) != nil, Date(importValue: row.updatedAt) != nil else { throw BackupImportError.invalidBackup }
                if let value = row.legacyCategory, CategoryKind(rawValue: value) == nil { throw BackupImportError.invalidBackup }
            }
            for row in (payload.categories ?? []).filter(\.isUserDefined) {
                if let value = row.legacyKindRawValue, CategoryKind(rawValue: value) == nil { throw BackupImportError.invalidBackup }
                if (payload.formatVersion ?? 0) >= 5 {
                    guard row.isHidden != nil, row.preciseDates?["createdAt"] != nil, row.preciseDates?["updatedAt"] != nil,
                          Date(importValue: row.createdAt) != nil, Date(importValue: row.updatedAt) != nil else { throw BackupImportError.invalidBackup }
                }
            }
        }
        var categorizedRows = 0
        var transactions: [Transaction] = []
        var budgets: [Budget] = []
        var skippedRows = 0

        for importedTransaction in payload.transactions ?? [] {
            guard let transaction = makeTransaction(
                from: importedTransaction,
                categoryLookup: categoryLookup,
                categorizedRows: &categorizedRows,
                preservesBackupValues: payload.formatVersion != nil
            ) else {
                skippedRows += 1
                continue
            }

            transactions.append(transaction)
        }

        for importedBudget in payload.budgets {
            guard let budget = makeBudget(from: importedBudget, categoryLookup: categoryLookup) else {
                skippedRows += 1
                continue
            }
            budgets.append(budget)
        }

        if payload.formatVersion == nil {
            CategoryStandardizationService.standardize(transactions: transactions)
        }
        // Native backups must be restored completely, never partially or silently.
        if payload.formatVersion != nil {
            guard skippedRows == 0,
                  Set(transactions.map(\.id)).count == transactions.count,
                  Set(budgets.map(\.id)).count == budgets.count else { throw BackupImportError.invalidBackup }
            let definitions = (payload.categories ?? []).filter(\.isUserDefined)
            guard Set(definitions.compactMap(\.id)).count == definitions.count,
                  definitions.allSatisfy({ $0.categoryDefinition != nil }) else { throw BackupImportError.invalidBackup }
            for item in payload.transactions ?? [] {
                guard item.id.flatMap(UUID.init(uuidString:)) != nil else { throw BackupImportError.invalidBackup }
            }
            for item in payload.budgets {
                guard item.id.flatMap(UUID.init(uuidString:)) != nil else { throw BackupImportError.invalidBackup }
            }
        }

        return PreparedImportResult(
            transactions: transactions,
            budgets: budgets,
            categoryDefinitions: (payload.categories ?? []).compactMap(\.categoryDefinition),
            includesBudgets: payload.includesBudgets,
            settings: payload.settings,
            categorizedRows: categorizedRows,
            skippedRows: skippedRows,
            mySavingsExportedAt: payload.isMySavings ? payload.exportedAt : nil,
            importReceipts: payload.importReceipts,
            savingsGoals: payload.savingsGoals,
            includesSavingsGoals: payload.includesSavingsGoals
        )
    }

    private static func importCSV(_ text: String) throws -> PreparedImportResult {
        let rows = text
            .split(whereSeparator: { $0.isNewline })
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard let headerRow = rows.first else {
            return PreparedImportResult(transactions: [], budgets: [], categoryDefinitions: [], includesBudgets: false, settings: nil, categorizedRows: 0, skippedRows: 0)
        }

        let headers = parseCSVRow(headerRow).map { $0.normalizedImportKey }
        guard Set(headers).count == headers.count else { throw BackupImportError.invalidBackup }
        var categorizedRows = 0
        var transactions: [Transaction] = []
        var skippedRows = 0

        for row in rows.dropFirst() {
            let values = parseCSVRow(row)
            let dictionary = Dictionary(uniqueKeysWithValues: zip(headers, values))
            let importedTransaction = ImportTransaction(
                id: dictionary.firstValue(for: ["id", "uuid"]),
                title: dictionary.firstValue(for: ["title", "name", "navn", "tittel"]) ?? "",
                amount: dictionary.firstValue(for: ["amount", "sum", "belop", "beløp"]) ?? "",
                type: dictionary.firstValue(for: ["type", "transactiontype", "posttype", "innut"]),
                dueDate: dictionary.firstValue(for: ["duedate", "date", "forfallsdato", "dato"]),
                paidDate: dictionary.firstValue(for: ["paiddate", "paymentdate", "receiveddate", "betaltdato", "mottattdato"]),
                status: dictionary.firstValue(for: ["status", "state", "tilstand"]),
                category: dictionary.firstValue(for: ["category", "categoryid", "kategori", "kategoriid", "client", "clientid", "klient", "klientid"]),
                recurrence: dictionary.firstValue(for: ["recurrence", "recurrencerule", "repeat", "gjentakelse"]),
                recurrenceIntervalMonths: dictionary.firstValue(for: ["recurrenceintervalmonths", "intervalmonths", "recurrenceinterval", "gjentakelseintervall", "intervallmaneder"]),
                notes: dictionary.firstValue(for: ["notes", "note", "comment", "notat", "kommentar"]),
                createdAt: dictionary.firstValue(for: ["createdat", "created", "opprettet"]),
                updatedAt: dictionary.firstValue(for: ["updatedat", "updated", "endret"]),
                isCompleted: dictionary.firstValue(for: ["iscompleted", "completed", "ferdig", "fullfort"]),
                isArchived: dictionary.firstValue(for: ["isarchived", "archived", "arkivert"])
            )

            guard let transaction = makeTransaction(
                from: importedTransaction,
                categoryLookup: .empty,
                categorizedRows: &categorizedRows
            ) else {
                skippedRows += 1
                continue
            }

            transactions.append(transaction)
        }

        CategoryStandardizationService.standardize(transactions: transactions)

        return PreparedImportResult(
            transactions: transactions,
            budgets: [],
            categoryDefinitions: [],
            includesBudgets: false,
            settings: nil,
            categorizedRows: categorizedRows,
            skippedRows: skippedRows
        )
    }

    private static func makeTransaction(
        from importedTransaction: ImportTransaction,
        categoryLookup: CategoryImportLookup,
        categorizedRows: inout Int,
        preservesBackupValues: Bool = false
    ) -> Transaction? {
        let title = preservesBackupValues ? importedTransaction.title : importedTransaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, let amount = Decimal(importAmount: importedTransaction.amount), let dueDate = Date(importValue: importedTransaction.dueDate) else {
            return nil
        }

        let id = importedTransaction.id.flatMap(UUID.init(uuidString:)) ?? UUID()
        let type = TransactionType(importValue: importedTransaction.type) ?? .expense
        let status = TransactionStatus(importValue: importedTransaction.status, type: type)
        let category = importedTransaction.legacyCategory.flatMap(CategoryKind.init(rawValue:)) ?? categoryLookup.category(for: importedTransaction.category)
        let customCategoryID = categoryLookup.customCategoryID(for: importedTransaction.category)
        if category != .other {
            categorizedRows += 1
        }
        let recurrence = RecurrenceRule(importValue: importedTransaction.recurrence) ?? .none
        let intervalMonths = preservesBackupValues
            ? importedTransaction.recurrenceIntervalMonths.flatMap(Int.init)
            : recurrence.intervalMonths(importedValue: importedTransaction.recurrenceIntervalMonths)
        let paidDate = Date(importValue: importedTransaction.paidDate)
        let isCompleted = Bool(importValue: importedTransaction.isCompleted) ?? (status == .paid || status == .received)
        let isArchived = Bool(importValue: importedTransaction.isArchived) ?? false

        return Transaction(
            id: id,
            title: title,
            amount: amount,
            type: type,
            dueDate: dueDate,
            paidDate: paidDate,
            status: status,
            category: category,
            customCategoryID: customCategoryID,
            recurrence: recurrence,
            recurrenceIntervalMonths: intervalMonths,
            recurrenceSeriesID: importedTransaction.recurrenceSeriesID.flatMap(UUID.init(uuidString:)),
            recurrenceAnchorDay: importedTransaction.recurrenceAnchorDay.flatMap(Int.init),
            notes: importedTransaction.notes ?? "",
            createdAt: Date(importValue: importedTransaction.createdAt) ?? .now,
            updatedAt: Date(importValue: importedTransaction.updatedAt) ?? .now,
            isCompleted: isCompleted,
            isArchived: isArchived
        )
    }

    private static func makeBudget(
        from importedBudget: ImportBudget,
        categoryLookup: CategoryImportLookup
    ) -> Budget? {
        guard
            let amount = Decimal(importAmount: importedBudget.amount),
            amount > .zero,
            let monthStart = Date(importValue: importedBudget.monthStart)
        else {
            return nil
        }

        return Budget(
            id: importedBudget.id.flatMap(UUID.init(uuidString:)) ?? UUID(),
            category: importedBudget.legacyCategory.flatMap(CategoryKind.init(rawValue:)) ?? categoryLookup.category(for: importedBudget.category),
            customCategoryID: categoryLookup.customCategoryID(for: importedBudget.category),
            monthStart: monthStart,
            amount: amount,
            createdAt: Date(importValue: importedBudget.createdAt) ?? .now,
            updatedAt: Date(importValue: importedBudget.updatedAt) ?? .now
        )
    }

    private static func parseCSVRow(_ row: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var isInsideQuotes = false

        let characters = Array(row)
        var index = characters.startIndex

        while index < characters.endIndex {
            let character = characters[index]
            if character == "\"" {
                let nextIndex = characters.index(after: index)
                if isInsideQuotes, nextIndex < characters.endIndex, characters[nextIndex] == "\"" {
                    currentValue.append("\"")
                    index = nextIndex
                } else {
                    isInsideQuotes.toggle()
                }
            } else if character == "," && !isInsideQuotes {
                values.append(currentValue.trimmingCharacters(in: .whitespacesAndNewlines))
                currentValue = ""
            } else {
                currentValue.append(character)
            }

            index = characters.index(after: index)
        }

        values.append(currentValue.trimmingCharacters(in: .whitespacesAndNewlines))
        return values
    }
}

enum BackupImportError: LocalizedError {
    case invalidBackup
    case unsupportedVersion
    var errorDescription: String? {
        switch self {
        case .invalidBackup: String(localized: "The backup is incomplete or invalid. No data was changed.")
        case .unsupportedVersion: String(localized: "This backup requires a newer version of SaldoPilot. No data was changed.")
        }
    }
}

private struct ImportPayload: Decodable {
    let sourceApp: String?
    let exportedAt: Date?
    let importReceipts: [ExternalImportReceiptRecord]
    let savingsGoals: [SavingsGoalRecord]
    let includesSavingsGoals: Bool
    var isMySavings: Bool { sourceApp == "MySavings" || (formatVersion == 4 && (categories ?? []).contains { $0.id?.hasPrefix("mysavings-") == true }) }
    let formatVersion: Int?
    let categories: [ImportCategory]?
    let transactions: [ImportTransaction]?
    let budgets: [ImportBudget]
    let includesBudgets: Bool
    let settings: BackupAppSettings?

    enum CodingKeys: String, CodingKey {
        case sourceApp, exportedAt, importReceipts, savingsGoals
        case formatVersion
        case categories
        case transactions
        case posts
        case poster
        case records
        case items
        case budgets
        case settings
    }

    init(from decoder: Decoder) throws {
        if let transactions = try? [ImportTransaction](from: decoder) {
            sourceApp = nil; exportedAt = nil; importReceipts = []; savingsGoals = []; includesSavingsGoals = false
            formatVersion = nil
            categories = []
            self.transactions = transactions
            budgets = []
            includesBudgets = false
            settings = nil
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        sourceApp = try container.decodeIfPresent(String.self, forKey: .sourceApp)
        exportedAt = try container.decodeIfPresent(Date.self, forKey: .exportedAt)
        importReceipts = try container.decodeIfPresent([ExternalImportReceiptRecord].self, forKey: .importReceipts) ?? []
        includesSavingsGoals = container.contains(.savingsGoals)
        savingsGoals = includesSavingsGoals ? try container.decode([SavingsGoalRecord].self, forKey: .savingsGoals) : []
        guard savingsGoals.allSatisfy(\.isValid), Set(savingsGoals.map(\.id)).count == savingsGoals.count else { throw BackupImportError.invalidBackup }
        guard importReceipts.allSatisfy(\.isValid), Set(importReceipts.map(\.sourceID)).count == importReceipts.count else { throw BackupImportError.invalidBackup }
        formatVersion = try container.decodeIfPresent(Int.self, forKey: .formatVersion)
        if let formatVersion, !(1...7).contains(formatVersion) { throw BackupImportError.unsupportedVersion }
        if formatVersion == 7 && !includesSavingsGoals { throw BackupImportError.invalidBackup }
        categories = container.contains(.categories) ? try container.decode([ImportCategory].self, forKey: .categories) : []
        transactions = try Self.decodeTransactions(from: container)
        includesBudgets = container.contains(.budgets)
        budgets = includesBudgets ? try container.decode([ImportBudget].self, forKey: .budgets) : []
        settings = try container.decodeIfPresent(BackupAppSettings.self, forKey: .settings)
        if formatVersion != nil, transactions == nil { throw BackupImportError.invalidBackup }
        if (formatVersion ?? 0) >= 5 {
            guard container.contains(.transactions), container.contains(.categories), includesBudgets else {
                throw BackupImportError.invalidBackup
            }
        }
    }

    private static func decodeTransactions(from container: KeyedDecodingContainer<CodingKeys>) throws -> [ImportTransaction]? {
        for key in [CodingKeys.transactions, .posts, .poster, .records, .items] {
            if container.contains(key) {
                return try container.decode([ImportTransaction].self, forKey: key)
            }
        }

        throw BackupImportError.invalidBackup
    }
}

private struct PreparedImportResult {
    let transactions: [Transaction]
    let budgets: [Budget]
    let categoryDefinitions: [CategoryDefinition]
    let includesBudgets: Bool
    let settings: BackupAppSettings?
    let categorizedRows: Int
    let skippedRows: Int
    var mySavingsExportedAt: Date? = nil
    var importReceipts: [ExternalImportReceiptRecord] = []
    var savingsGoals: [SavingsGoalRecord] = []
    var includesSavingsGoals: Bool = false
}

private struct ImportBudget: Decodable {
    let id: String?
    let category: String?
    let legacyCategory: String?
    let monthStart: String?
    let amount: String
    let preciseDates: [String: Double]?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case category
        case legacyCategory
        case monthStart
        case amount
        case createdAt
        case updatedAt
        case preciseDates
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeFlexibleString(forKeys: [.id])
        category = try container.decodeFlexibleString(forKeys: [.category])
        legacyCategory = try container.decodeFlexibleString(forKeys: [.legacyCategory])
        monthStart = try container.decodeFlexibleString(forKeys: [.monthStart])
        amount = try container.decodeFlexibleString(forKeys: [.amount]) ?? ""
        preciseDates = try container.decodeIfPresent([String: Double].self, forKey: .preciseDates)
        createdAt = try container.decodeFlexibleString(forKeys: [.createdAt])
        updatedAt = try container.decodeFlexibleString(forKeys: [.updatedAt])
    }
}

private struct ImportCategory: Decodable {
    let id: String?
    let name: String?
    let icon: String?
    let colorIdentifier: String?
    let legacyKindRawValue: String?
    let excludesFromSavingsTips: Bool?
    let isUserDefined: Bool
    let isHidden: Bool?
    let preciseDates: [String: Double]?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case navn
        case title
        case tittel
        case icon
        case ikon
        case colorIdentifier
        case color
        case colorId
        case farge
        case legacyKindRawValue
        case excludesFromSavingsTips
        case isUserDefined
        case isHidden
        case createdAt
        case updatedAt
        case preciseDates
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeFlexibleString(forKeys: [.id])
        name = try container.decodeFlexibleString(forKeys: [.name, .navn, .title, .tittel])
        icon = try container.decodeFlexibleString(forKeys: [.icon, .ikon])
        colorIdentifier = try container.decodeFlexibleString(forKeys: [.colorIdentifier, .color, .colorId, .farge])
        legacyKindRawValue = try container.decodeFlexibleString(forKeys: [.legacyKindRawValue])
        excludesFromSavingsTips = try container.decodeIfPresent(Bool.self, forKey: .excludesFromSavingsTips)
        isUserDefined = try container.decodeIfPresent(Bool.self, forKey: .isUserDefined) ?? false
        isHidden = try container.decodeIfPresent(Bool.self, forKey: .isHidden)
        preciseDates = try container.decodeIfPresent([String: Double].self, forKey: .preciseDates)
        createdAt = try container.decodeFlexibleString(forKeys: [.createdAt])
        updatedAt = try container.decodeFlexibleString(forKeys: [.updatedAt])
    }

    var categoryDefinition: CategoryDefinition? {
        guard isUserDefined, let id, let name, !name.isEmpty else { return nil }
        return CategoryDefinition(
            id: id,
            name: name,
            systemImage: icon ?? "tag",
            colorName: colorIdentifier ?? "blue",
            legacyKindRawValue: legacyKindRawValue,
            isHidden: isHidden ?? false,
            excludesFromSavingsTips: excludesFromSavingsTips,
            createdAt: Date(importValue: createdAt) ?? .now,
            updatedAt: Date(importValue: updatedAt) ?? .now
        )
    }
}

private struct ImportTransaction: Decodable {
    let id: String?
    let title: String
    let amount: String
    let type: String?
    let dueDate: String?
    let paidDate: String?
    let status: String?
    let category: String?
    let legacyCategory: String?
    let recurrence: String?
    let recurrenceIntervalMonths: String?
    let recurrenceSeriesID: String?
    let recurrenceAnchorDay: String?
    let notes: String?
    let preciseDates: [String: Double]?
    let createdAt: String?
    let updatedAt: String?
    let isCompleted: String?
    let isArchived: String?

    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case title
        case name
        case navn
        case tittel
        case amount
        case sum
        case belop
        case beløp
        case type
        case transactionType
        case postType
        case innUt
        case dueDate
        case date
        case forfallsdato
        case dato
        case paidDate
        case paymentDate
        case receivedDate
        case betaltDato
        case mottattDato
        case status
        case state
        case tilstand
        case category
        case legacyCategory
        case categoryId
        case kategori
        case kategoriId
        case client
        case clientId
        case klient
        case klientId
        case recurrence
        case recurrenceRule
        case `repeat`
        case gjentakelse
        case recurrenceIntervalMonths
        case recurrenceSeriesID
        case recurrenceAnchorDay
        case intervalMonths
        case recurrenceInterval
        case gjentakelseIntervall
        case intervallManeder
        case notes
        case note
        case comment
        case notat
        case kommentar
        case preciseDates
        case createdAt
        case created
        case opprettet
        case updatedAt
        case updated
        case endret
        case isCompleted
        case completed
        case ferdig
        case fullfort
        case isArchived
        case archived
        case arkivert
    }

    init(
        id: String? = nil,
        title: String,
        amount: String,
        type: String?,
        dueDate: String?,
        paidDate: String?,
        status: String?,
        category: String?,
        legacyCategory: String? = nil,
        recurrence: String?,
        recurrenceIntervalMonths: String?,
        recurrenceSeriesID: String? = nil,
        recurrenceAnchorDay: String? = nil,
        notes: String?,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        isCompleted: String? = nil,
        isArchived: String? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.type = type
        self.dueDate = dueDate
        self.paidDate = paidDate
        self.status = status
        self.category = category
        self.legacyCategory = legacyCategory
        self.recurrence = recurrence
        self.recurrenceIntervalMonths = recurrenceIntervalMonths
        self.recurrenceSeriesID = recurrenceSeriesID
        self.recurrenceAnchorDay = recurrenceAnchorDay
        self.notes = notes
        self.preciseDates = nil
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isCompleted = isCompleted
        self.isArchived = isArchived
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeFlexibleString(forKeys: [.id, .uuid])
        title = try container.decodeFlexibleString(forKeys: [.title, .name, .navn, .tittel]) ?? ""
        amount = try container.decodeFlexibleString(forKeys: [.amount, .sum, .belop, .beløp]) ?? ""
        type = try container.decodeFlexibleString(forKeys: [.type, .transactionType, .postType, .innUt])
        dueDate = try container.decodeFlexibleString(forKeys: [.dueDate, .date, .forfallsdato, .dato])
        paidDate = try container.decodeFlexibleString(forKeys: [.paidDate, .paymentDate, .receivedDate, .betaltDato, .mottattDato])
        status = try container.decodeFlexibleString(forKeys: [.status, .state, .tilstand])
        category = try container.decodeFlexibleString(forKeys: [.category, .categoryId, .kategori, .kategoriId, .client, .clientId, .klient, .klientId])
        legacyCategory = try container.decodeFlexibleString(forKeys: [.legacyCategory])
        recurrence = try container.decodeFlexibleString(forKeys: [.recurrence, .recurrenceRule, .repeat, .gjentakelse])
        recurrenceIntervalMonths = try container.decodeFlexibleString(forKeys: [.recurrenceIntervalMonths, .intervalMonths, .recurrenceInterval, .gjentakelseIntervall, .intervallManeder])
        recurrenceSeriesID = try container.decodeFlexibleString(forKeys: [.recurrenceSeriesID])
        recurrenceAnchorDay = try container.decodeFlexibleString(forKeys: [.recurrenceAnchorDay])
        notes = try container.decodeFlexibleString(forKeys: [.notes, .note, .comment, .notat, .kommentar])
        preciseDates = try container.decodeIfPresent([String: Double].self, forKey: .preciseDates)
        createdAt = try container.decodeFlexibleString(forKeys: [.createdAt, .created, .opprettet])
        updatedAt = try container.decodeFlexibleString(forKeys: [.updatedAt, .updated, .endret])
        isCompleted = try container.decodeFlexibleString(forKeys: [.isCompleted, .completed, .ferdig, .fullfort])
        isArchived = try container.decodeFlexibleString(forKeys: [.isArchived, .archived, .arkivert])
    }
}

private struct CategoryImportLookup {
    static let empty = CategoryImportLookup(categories: [])

    private let categoriesByKey: [String: CategoryKind]
    private let customIDsByKey: [String: String]
    private let categoriesByID: [String: CategoryKind]
    private let customIDsByID: [String: String]

    init(categories: [ImportCategory]) {
        var categoriesByKey: [String: CategoryKind] = [:]
        var customIDsByKey: [String: String] = [:]
        var categoriesByID: [String: CategoryKind] = [:]
        var customIDsByID: [String: String] = [:]

        for category in categories {
            let resolvedCategory = category.legacyKindRawValue.flatMap(CategoryKind.init(rawValue:)) ?? category.id.flatMap(CategoryKind.init(rawValue:)) ?? CategoryKind.matching(category.name ?? category.id)
            if let id = category.id {
                categoriesByID[id] = resolvedCategory
                if category.isUserDefined, category.legacyKindRawValue == nil { customIDsByID[id] = id }
            }
            for value in [category.id, category.name] {
                guard let key = value?.normalizedImportKey, !key.isEmpty else { continue }
                categoriesByKey[key] = resolvedCategory
                if category.isUserDefined, category.legacyKindRawValue == nil, let id = category.id {
                    customIDsByKey[key] = id
                }
            }
        }

        self.categoriesByKey = categoriesByKey
        self.customIDsByKey = customIDsByKey
        self.categoriesByID = categoriesByID
        self.customIDsByID = customIDsByID
    }

    func category(for importedValue: String?) -> CategoryKind {
        guard let importedValue, !importedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .other
        }

        if let category = categoriesByID[importedValue] { return category }
        let key = importedValue.normalizedImportKey
        return categoriesByKey[key] ?? CategoryKind.matching(importedValue)
    }

    func customCategoryID(for importedValue: String?) -> String? {
        guard let importedValue else { return nil }
        if categoriesByID[importedValue] != nil { return customIDsByID[importedValue] }
        return customIDsByKey[importedValue.normalizedImportKey]
    }
}

private extension KeyedDecodingContainer {
    func decodeFlexibleString(forKey key: Key) throws -> String? {
        let dateKeys = ["dueDate", "paidDate", "monthStart", "createdAt", "updatedAt"]
        if dateKeys.contains(key.stringValue), let preciseKey = allKeys.first(where: { $0.stringValue == "preciseDates" }) {
            let dates = try decode([String: Double].self, forKey: preciseKey)
            if let seconds = dates[key.stringValue] {
                guard seconds.isFinite else { throw BackupImportError.invalidBackup }
                return "reference:" + String(seconds)
            }
        }
        if let stringValue = try? decodeIfPresent(String.self, forKey: key) {
            return stringValue
        }
        if let decimalValue = try? decodeIfPresent(Decimal.self, forKey: key) {
            return decimalValue.description
        }
        if let doubleValue = try? decodeIfPresent(Double.self, forKey: key) {
            return doubleValue.description
        }
        if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return intValue.description
        }
        if let boolValue = try? decodeIfPresent(Bool.self, forKey: key) {
            return boolValue.description
        }
        return nil
    }

    func decodeFlexibleString(forKeys keys: [Key]) throws -> String? {
        for key in keys {
            if let value = try decodeFlexibleString(forKey: key) {
                return value
            }
        }

        return nil
    }
}

private extension Decimal {
    init?(importAmount value: String) {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        guard normalized.range(of: #"^[+-]?[0-9]+(?:\.[0-9]+)?$"#, options: .regularExpression) != nil else { return nil }
        self.init(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }
}

private extension Date {
    init?(importValue value: String?) {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedValue.hasPrefix("reference:"), let seconds = Double(trimmedValue.dropFirst(10)), seconds.isFinite {
            self = Date(timeIntervalSinceReferenceDate: seconds)
            return
        }
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions.insert(.withFractionalSeconds)
        if let date = fractionalFormatter.date(from: trimmedValue) {
            self = date
            return
        }
        if let date = ISO8601DateFormatter().date(from: trimmedValue) {
            self = date
            return
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: trimmedValue) {
            self = date
            return
        }

        formatter.dateFormat = "dd.MM.yyyy"
        if let date = formatter.date(from: trimmedValue) {
            self = date
            return
        }

        return nil
    }
}

private extension TransactionType {
    init?(importValue value: String?) {
        guard let value else { return nil }
        switch value.normalizedImportKey {
        case "income", "inntekt", "received", "รายรับ":
            self = .income
        case "expense", "utgift", "payment", "รายจ่าย":
            self = .expense
        default:
            return nil
        }
    }
}

private extension TransactionStatus {
    init(importValue value: String?, type: TransactionType) {
        guard let value else {
            self = .pending
            return
        }

        switch value.normalizedImportKey {
        case "paid", "betalt":
            self = .paid
        case "received", "mottatt":
            self = .received
        case "overdue", "forfalt":
            self = .overdue
        case "cancelled", "canceled", "kansellert":
            self = .cancelled
        default:
            self = type == .income && value.normalizedImportKey == "completed" ? .received : .pending
        }
    }
}

private extension RecurrenceRule {
    init?(importValue value: String?) {
        guard let value else { return nil }
        switch value.normalizedImportKey {
        case "none", "ingen", "":
            self = .none
        case "monthly", "manedlig", "monthlyrecurrence":
            self = .monthly
        case "every n months", "everynmonths", "everyfewmonths":
            self = .everyNMonths
        case "quarterly", "kvartalsvis":
            self = .quarterly
        case "halfyearly", "half yearly", "halvarlig":
            self = .halfYearly
        case "yearly", "arlig":
            self = .yearly
        case "custom", "egendefinert":
            self = .custom
        default:
            return nil
        }
    }

    func intervalMonths(importedValue value: String?) -> Int? {
        if let importedInterval = Int((value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)), importedInterval > 0 {
            return importedInterval
        }

        switch self {
        case .everyNMonths, .custom:
            return nil
        case .none, .monthly:
            return nil
        case .quarterly:
            return 3
        case .halfYearly:
            return 6
        case .yearly:
            return 12
        }
    }
}

private extension Bool {
    init?(importValue value: String?) {
        guard let value else { return nil }

        switch value.normalizedImportKey {
        case "true", "yes", "ja", "1", "completed", "ferdig", "fullfort":
            self = true
        case "false", "no", "nei", "0":
            self = false
        default:
            return nil
        }
    }
}

private extension Dictionary where Key == String, Value == String {
    func firstValue(for keys: [String]) -> String? {
        for key in keys {
            if let value = self[key.normalizedImportKey] {
                return value
            }
        }

        return nil
    }
}

private extension String {
    var normalizedImportKey: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
}
