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
    let skippedRows: Int

    var message: String {
        if replacedTransactions > 0 {
            String(localized: "Imported \(transactionsCreated) transactions. Replaced \(replacedTransactions) existing transactions. Matched categories for \(categorizedRows) rows. Skipped \(skippedRows) rows.")
        } else {
            String(localized: "Imported \(transactionsCreated) transactions. Matched categories for \(categorizedRows) rows. Skipped \(skippedRows) rows.")
        }
    }
}

enum ImportMode {
    case merge
    case replaceExisting
}

enum ImportService {
    static func importFile(
        at url: URL,
        mode: ImportMode = .merge,
        modelContext: ModelContext
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
            importResult = importCSV(text)
        } else {
            importResult = try importJSON(data)
        }

        var replacedTransactions = 0
        if mode == .replaceExisting {
            let existingTransactions = try modelContext.fetch(FetchDescriptor<Transaction>())
            for transaction in existingTransactions {
                modelContext.delete(transaction)
            }
            replacedTransactions = existingTransactions.count
        }

        for transaction in importResult.transactions {
            modelContext.insert(transaction)
        }

        return ImportSummary(
            categorizedRows: importResult.categorizedRows,
            transactionsCreated: importResult.transactions.count,
            replacedTransactions: replacedTransactions,
            skippedRows: importResult.skippedRows
        )
    }

    private static func importJSON(_ data: Data) throws -> PreparedImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let payload = try decoder.decode(ImportPayload.self, from: data)
        let categoryLookup = CategoryImportLookup(categories: payload.categories ?? [])
        var categorizedRows = 0
        var transactions: [Transaction] = []
        var skippedRows = 0

        for importedTransaction in payload.transactions ?? [] {
            guard let transaction = makeTransaction(
                from: importedTransaction,
                categoryLookup: categoryLookup,
                categorizedRows: &categorizedRows
            ) else {
                skippedRows += 1
                continue
            }

            transactions.append(transaction)
        }

        return PreparedImportResult(
            transactions: transactions,
            categorizedRows: categorizedRows,
            skippedRows: skippedRows
        )
    }

    private static func importCSV(_ text: String) -> PreparedImportResult {
        let rows = text
            .split(whereSeparator: { $0.isNewline })
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard let headerRow = rows.first else {
            return PreparedImportResult(transactions: [], categorizedRows: 0, skippedRows: 0)
        }

        let headers = parseCSVRow(headerRow).map { $0.normalizedImportKey }
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

        return PreparedImportResult(
            transactions: transactions,
            categorizedRows: categorizedRows,
            skippedRows: skippedRows
        )
    }

    private static func makeTransaction(
        from importedTransaction: ImportTransaction,
        categoryLookup: CategoryImportLookup,
        categorizedRows: inout Int
    ) -> Transaction? {
        let title = importedTransaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, let amount = Decimal(importAmount: importedTransaction.amount), let dueDate = Date(importValue: importedTransaction.dueDate) else {
            return nil
        }

        let id = importedTransaction.id.flatMap(UUID.init(uuidString:)) ?? UUID()
        let type = TransactionType(importValue: importedTransaction.type) ?? .expense
        let status = TransactionStatus(importValue: importedTransaction.status, type: type)
        let category = categoryLookup.category(for: importedTransaction.category)
        if category != .other {
            categorizedRows += 1
        }
        let recurrence = RecurrenceRule(importValue: importedTransaction.recurrence) ?? .none
        let intervalMonths = recurrence.intervalMonths(
            importedValue: importedTransaction.recurrenceIntervalMonths
        )
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
            recurrence: recurrence,
            recurrenceIntervalMonths: intervalMonths,
            notes: importedTransaction.notes ?? "",
            createdAt: Date(importValue: importedTransaction.createdAt) ?? .now,
            updatedAt: Date(importValue: importedTransaction.updatedAt) ?? .now,
            isCompleted: isCompleted,
            isArchived: isArchived
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

private struct ImportPayload: Decodable {
    let categories: [ImportCategory]?
    let transactions: [ImportTransaction]?
}

private struct PreparedImportResult {
    let transactions: [Transaction]
    let categorizedRows: Int
    let skippedRows: Int
}

private struct ImportCategory: Decodable {
    let id: String?
    let name: String?
    let icon: String?
    let colorIdentifier: String?

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
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeFlexibleString(forKeys: [.id])
        name = try container.decodeFlexibleString(forKeys: [.name, .navn, .title, .tittel])
        icon = try container.decodeFlexibleString(forKeys: [.icon, .ikon])
        colorIdentifier = try container.decodeFlexibleString(forKeys: [.colorIdentifier, .color, .colorId, .farge])
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
    let recurrence: String?
    let recurrenceIntervalMonths: String?
    let notes: String?
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
        case intervalMonths
        case recurrenceInterval
        case gjentakelseIntervall
        case intervallManeder
        case notes
        case note
        case comment
        case notat
        case kommentar
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
        recurrence: String?,
        recurrenceIntervalMonths: String?,
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
        self.recurrence = recurrence
        self.recurrenceIntervalMonths = recurrenceIntervalMonths
        self.notes = notes
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
        recurrence = try container.decodeFlexibleString(forKeys: [.recurrence, .recurrenceRule, .repeat, .gjentakelse])
        recurrenceIntervalMonths = try container.decodeFlexibleString(forKeys: [.recurrenceIntervalMonths, .intervalMonths, .recurrenceInterval, .gjentakelseIntervall, .intervallManeder])
        notes = try container.decodeFlexibleString(forKeys: [.notes, .note, .comment, .notat, .kommentar])
        createdAt = try container.decodeFlexibleString(forKeys: [.createdAt, .created, .opprettet])
        updatedAt = try container.decodeFlexibleString(forKeys: [.updatedAt, .updated, .endret])
        isCompleted = try container.decodeFlexibleString(forKeys: [.isCompleted, .completed, .ferdig, .fullfort])
        isArchived = try container.decodeFlexibleString(forKeys: [.isArchived, .archived, .arkivert])
    }
}

private struct CategoryImportLookup {
    static let empty = CategoryImportLookup(categories: [])

    private let categoriesByKey: [String: CategoryKind]

    init(categories: [ImportCategory]) {
        var categoriesByKey: [String: CategoryKind] = [:]

        for category in categories {
            let resolvedCategory = CategoryKind.matching(category.name ?? category.id)
            for value in [category.id, category.name] {
                guard let key = value?.normalizedImportKey, !key.isEmpty else { continue }
                categoriesByKey[key] = resolvedCategory
            }
        }

        self.categoriesByKey = categoriesByKey
    }

    func category(for importedValue: String?) -> CategoryKind {
        guard let importedValue, !importedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .other
        }

        let key = importedValue.normalizedImportKey
        return categoriesByKey[key] ?? CategoryKind.matching(importedValue)
    }
}

private extension KeyedDecodingContainer {
    func decodeFlexibleString(forKey key: Key) throws -> String? {
        if let stringValue = try decodeIfPresent(String.self, forKey: key) {
            return stringValue
        }
        if let decimalValue = try decodeIfPresent(Decimal.self, forKey: key) {
            return decimalValue.description
        }
        if let intValue = try decodeIfPresent(Int.self, forKey: key) {
            return intValue.description
        }
        if let boolValue = try decodeIfPresent(Bool.self, forKey: key) {
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
        self.init(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }
}

private extension Date {
    init?(importValue value: String?) {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

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
