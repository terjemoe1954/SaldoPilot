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
    let skippedRows: Int

    var message: String {
        String(localized: "Imported \(transactionsCreated) transactions. Matched categories for \(categorizedRows) rows. Skipped \(skippedRows) rows.")
    }
}

enum ImportService {
    static func importFile(at url: URL, modelContext: ModelContext) throws -> ImportSummary {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        let fileExtension = url.pathExtension.lowercased()

        if fileExtension == "csv" {
            let text = String(decoding: data, as: UTF8.self)
            return importCSV(text, modelContext: modelContext)
        }

        return try importJSON(data, modelContext: modelContext)
    }

    private static func importJSON(_ data: Data, modelContext: ModelContext) throws -> ImportSummary {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let payload = try decoder.decode(ImportPayload.self, from: data)
        var categorizedRows = 0
        var transactionsCreated = 0
        var skippedRows = 0

        for importedTransaction in payload.transactions ?? [] {
            guard let transaction = makeTransaction(from: importedTransaction, categorizedRows: &categorizedRows) else {
                skippedRows += 1
                continue
            }

            modelContext.insert(transaction)
            transactionsCreated += 1
        }

        return ImportSummary(categorizedRows: categorizedRows, transactionsCreated: transactionsCreated, skippedRows: skippedRows)
    }

    private static func importCSV(_ text: String, modelContext: ModelContext) -> ImportSummary {
        let rows = text
            .split(whereSeparator: { $0.isNewline })
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard let headerRow = rows.first else {
            return ImportSummary(categorizedRows: 0, transactionsCreated: 0, skippedRows: 0)
        }

        let headers = parseCSVRow(headerRow).map { $0.normalizedImportKey }
        var categorizedRows = 0
        var transactionsCreated = 0
        var skippedRows = 0

        for row in rows.dropFirst() {
            let values = parseCSVRow(row)
            let dictionary = Dictionary(uniqueKeysWithValues: zip(headers, values))
            let importedTransaction = ImportTransaction(
                title: dictionary["title"] ?? dictionary["name"] ?? "",
                amount: dictionary["amount"] ?? "",
                type: dictionary["type"],
                dueDate: dictionary["duedate"] ?? dictionary["date"],
                paidDate: dictionary["paiddate"],
                status: dictionary["status"],
                category: dictionary["category"],
                recurrence: dictionary["recurrence"],
                recurrenceIntervalMonths: dictionary["recurrenceintervalmonths"],
                notes: dictionary["notes"]
            )

            guard let transaction = makeTransaction(from: importedTransaction, categorizedRows: &categorizedRows) else {
                skippedRows += 1
                continue
            }

            modelContext.insert(transaction)
            transactionsCreated += 1
        }

        return ImportSummary(categorizedRows: categorizedRows, transactionsCreated: transactionsCreated, skippedRows: skippedRows)
    }

    private static func makeTransaction(
        from importedTransaction: ImportTransaction,
        categorizedRows: inout Int
    ) -> Transaction? {
        let title = importedTransaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, let amount = Decimal(importAmount: importedTransaction.amount), let dueDate = Date(importValue: importedTransaction.dueDate) else {
            return nil
        }

        let type = TransactionType(importValue: importedTransaction.type) ?? .expense
        let status = TransactionStatus(importValue: importedTransaction.status, type: type)
        let category = CategoryKind.matching(importedTransaction.category)
        if category != .other || !(importedTransaction.category ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            categorizedRows += 1
        }
        let recurrence = RecurrenceRule(importValue: importedTransaction.recurrence) ?? .none
        let intervalMonths = Int((importedTransaction.recurrenceIntervalMonths ?? "").trimmingCharacters(in: .whitespacesAndNewlines))
        let paidDate = Date(importValue: importedTransaction.paidDate)
        let isCompleted = status == .paid || status == .received

        return Transaction(
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
            isCompleted: isCompleted
        )
    }

    private static func parseCSVRow(_ row: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var isInsideQuotes = false

        for character in row {
            if character == "\"" {
                isInsideQuotes.toggle()
            } else if character == "," && !isInsideQuotes {
                values.append(currentValue.trimmingCharacters(in: .whitespacesAndNewlines))
                currentValue = ""
            } else {
                currentValue.append(character)
            }
        }

        values.append(currentValue.trimmingCharacters(in: .whitespacesAndNewlines))
        return values
    }
}

private struct ImportPayload: Decodable {
    let categories: [ImportCategory]?
    let transactions: [ImportTransaction]?
}

private struct ImportCategory: Decodable {
    let id: String?
    let name: String?
    let icon: String?
    let colorIdentifier: String?
}

private struct ImportTransaction: Decodable {
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

    enum CodingKeys: String, CodingKey {
        case title
        case name
        case amount
        case type
        case dueDate
        case date
        case paidDate
        case status
        case category
        case recurrence
        case recurrenceIntervalMonths
        case notes
    }

    init(
        title: String,
        amount: String,
        type: String?,
        dueDate: String?,
        paidDate: String?,
        status: String?,
        category: String?,
        recurrence: String?,
        recurrenceIntervalMonths: String?,
        notes: String?
    ) {
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
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? container.decodeIfPresent(String.self, forKey: .name) ?? ""
        amount = try container.decodeFlexibleString(forKey: .amount) ?? ""
        type = try container.decodeIfPresent(String.self, forKey: .type)
        dueDate = try container.decodeIfPresent(String.self, forKey: .dueDate) ?? container.decodeIfPresent(String.self, forKey: .date)
        paidDate = try container.decodeIfPresent(String.self, forKey: .paidDate)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        recurrence = try container.decodeIfPresent(String.self, forKey: .recurrence)
        recurrenceIntervalMonths = try container.decodeFlexibleString(forKey: .recurrenceIntervalMonths)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
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
}

private extension String {
    var normalizedImportKey: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
}
