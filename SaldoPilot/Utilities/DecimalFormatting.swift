//
//  DecimalFormatting.swift
//  SaldoPilot
//
//  Created by Terje Moe on 13/09/2026.
//

import Foundation

extension Decimal {
    var formattedCurrency: String {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "NOK"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.roundingMode = .halfUp
        return formatter.string(from: NSDecimalNumber(decimal: self)) ?? description
    }

    static func localizedValue(from text: String) -> Decimal? {
        var value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }

        for currencyText in ["NOK", "kr"] {
            value = value.replacingOccurrences(
                of: currencyText,
                with: "",
                options: [.caseInsensitive, .literal]
            )
        }

        value = value
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: "\u{202F}", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "'", with: "")

        guard !value.isEmpty else { return nil }
        let allowedCharacters = CharacterSet(charactersIn: "+-0123456789.,")
        guard value.unicodeScalars.allSatisfy(allowedCharacters.contains) else { return nil }
        guard value.filter({ $0 == "+" || $0 == "-" }).count <= 1 else { return nil }
        if let signIndex = value.firstIndex(where: { $0 == "+" || $0 == "-" }), signIndex != value.startIndex {
            return nil
        }

        let commaIndices = value.indices.filter { value[$0] == "," }
        let pointIndices = value.indices.filter { value[$0] == "." }

        if pointIndices.isEmpty, commaIndices.count == 1, let comma = commaIndices.first {
            let trailingCount = value.distance(from: value.index(after: comma), to: value.endIndex)
            guard (1...3).contains(trailingCount) else { return nil }
        }
        if commaIndices.isEmpty, pointIndices.count == 1, let point = pointIndices.first {
            let trailingCount = value.distance(from: value.index(after: point), to: value.endIndex)
            guard (1...3).contains(trailingCount) else { return nil }
        }
        if pointIndices.isEmpty, commaIndices.count > 1 {
            guard value.components(separatedBy: ",").dropFirst().allSatisfy({ $0.count == 3 }) else { return nil }
        }
        if commaIndices.isEmpty, pointIndices.count > 1 {
            guard value.components(separatedBy: ".").dropFirst().allSatisfy({ $0.count == 3 }) else { return nil }
        }

        let decimalSeparatorIndex: String.Index?

        if let lastComma = commaIndices.last, let lastPoint = pointIndices.last {
            decimalSeparatorIndex = max(lastComma, lastPoint)
        } else if commaIndices.count == 1, let comma = commaIndices.first {
            let fractionCount = value.distance(from: value.index(after: comma), to: value.endIndex)
            decimalSeparatorIndex = (1...2).contains(fractionCount) ? comma : nil
        } else if pointIndices.count == 1, let point = pointIndices.first {
            let fractionCount = value.distance(from: value.index(after: point), to: value.endIndex)
            decimalSeparatorIndex = (1...2).contains(fractionCount) ? point : nil
        } else {
            decimalSeparatorIndex = nil
        }

        let fractionCount = decimalSeparatorIndex.map {
            value.distance(from: value.index(after: $0), to: value.endIndex)
        } ?? 0
        guard fractionCount <= 2 else { return nil }

        var digits = value.filter { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        if fractionCount > 0 {
            digits.insert(".", at: digits.index(digits.endIndex, offsetBy: -fractionCount))
        }
        if value.first == "-" {
            digits.insert("-", at: digits.startIndex)
        }

        return Decimal(string: digits, locale: Locale(identifier: "en_US_POSIX"))
    }

    static func currencyAmount(from text: String) -> Decimal? {
        guard let amount = localizedValue(from: text), amount > .zero else { return nil }
        return amount
    }
}

enum AccountBalanceCalculator {
    static func availableBalance(
        openingBalanceText: String,
        openingBalanceDate: Date,
        transactions: [Transaction],
        calendar: Calendar = .current
    ) -> Decimal? {
        guard let openingBalance = Decimal.localizedValue(from: openingBalanceText) else {
            return nil
        }

        let startDate = calendar.startOfDay(for: openingBalanceDate)
        return transactions.reduce(openingBalance) { balance, transaction in
            guard
                !transaction.isArchived,
                transaction.status != .cancelled,
                transaction.isSettled,
                let paidDate = transaction.paidDate,
                paidDate >= startDate
            else {
                return balance
            }

            switch transaction.type {
            case .income:
                return balance + transaction.amount
            case .expense:
                return balance - transaction.amount
            }
        }
    }
}
