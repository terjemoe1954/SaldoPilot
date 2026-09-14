//
//  Category.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import SwiftUI

enum CategoryKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case home
    case groceries
    case transport
    case insurance
    case subscriptions
    case communication
    case clothing
    case health
    case entertainment
    case gifts
    case savings
    case payrollDeduction
    case income
    case developer
    case other

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .home:
            "Home"
        case .groceries:
            "Groceries"
        case .transport:
            "Transport"
        case .insurance:
            "Insurance"
        case .subscriptions:
            "Subscriptions"
        case .communication:
            "Communication"
        case .clothing:
            "Clothing"
        case .health:
            "Health"
        case .entertainment:
            "Entertainment"
        case .gifts:
            "Gifts"
        case .savings:
            "Savings"
        case .payrollDeduction:
            "Payroll deduction"
        case .income:
            "Income"
        case .developer:
            "Developer"
        case .other:
            "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            "house"
        case .groceries:
            "cart"
        case .transport:
            "car"
        case .insurance:
            "shield"
        case .subscriptions:
            "repeat"
        case .communication:
            "phone"
        case .clothing:
            "tshirt"
        case .health:
            "cross.case"
        case .entertainment:
            "popcorn"
        case .gifts:
            "gift"
        case .savings:
            "banknote"
        case .payrollDeduction:
            "doc.text.magnifyingglass"
        case .income:
            "arrow.down.circle"
        case .developer:
            "curlybraces"
        case .other:
            "tag"
        }
    }

    var tint: Color {
        switch self {
        case .home:
            .blue
        case .groceries:
            .green
        case .transport:
            .orange
        case .insurance:
            .indigo
        case .subscriptions:
            .purple
        case .communication:
            .teal
        case .clothing:
            .pink
        case .health:
            .red
        case .entertainment:
            .yellow
        case .gifts:
            .purple
        case .savings:
            .mint
        case .payrollDeduction:
            .brown
        case .income:
            .green
        case .developer:
            .cyan
        case .other:
            .gray
        }
    }

    static func matching(_ value: String?) -> CategoryKind {
        guard let value else { return .other }
        let normalizedValue = value.normalizedCategoryKey
        guard !normalizedValue.isEmpty else { return .other }

        if let exactMatch = allCases.first(where: { $0.rawValue == normalizedValue }) {
            return exactMatch
        }

        return allCases.first { category in
            category.searchTerms.contains { term in
                normalizedValue.contains(term.normalizedCategoryKey)
            }
        } ?? .other
    }

    static var sortedForDisplay: [CategoryKind] {
        allCases.sorted {
            String(localized: $0.title).localizedCaseInsensitiveCompare(String(localized: $1.title)) == .orderedAscending
        }
    }

    func matches(transactionTitle: String) -> Bool {
        let normalizedTitle = transactionTitle.normalizedCategoryKey
        return searchTerms.contains { normalizedTitle.contains($0.normalizedCategoryKey) }
    }

    private var searchTerms: [String] {
        switch self {
        case .home:
            ["home", "housing", "rent", "mortgage", "electricity", "power", "bolig", "husleie", "strom", "strøm", "บ้าน", "ค่าเช่า"]
        case .groceries:
            ["groceries", "grocery", "food", "supermarket", "mat", "dagligvarer", "butikk", "อาหาร", "ของชำ"]
        case .transport:
            ["transport", "car", "bus", "train", "taxi", "fuel", "bensin", "bil", "transport", "รถ", "เดินทาง"]
        case .insurance:
            ["insurance", "forsikring", "ประกัน"]
        case .subscriptions:
            ["subscription", "subscriptions", "netflix", "spotify", "abonnement", "สมาชิก"]
        case .communication:
            ["communication", "phone", "mobile", "internet", "mobil", "telefon", "โทรศัพท์", "อินเทอร์เน็ต"]
        case .clothing:
            ["clothing", "clothes", "shoes", "klær", "klaer", "sko", "เสื้อผ้า", "รองเท้า"]
        case .health:
            ["health", "doctor", "pharmacy", "medicine", "helse", "lege", "apotek", "สุขภาพ", "ยา"]
        case .entertainment:
            ["entertainment", "movie", "cinema", "game", "restaurant", "underholdning", "kino", "spill", "บันเทิง"]
        case .gifts:
            ["gift", "gifts", "present", "presents", "gave", "gaver", "presang", "ของขวัญ"]
        case .savings:
            ["savings", "saving", "save", "spare", "sparing", "ออม", "เงินออม"]
        case .payrollDeduction:
            ["payroll deduction", "wage garnishment", "garnishment", "attachment of earnings", "påleggstrekk", "paleggstrekk", "trekk", "utleggstrekk", "การหักเงินเดือน", "หักเงินเดือนตามคำสั่ง"]
        case .income:
            ["income", "salary", "wage", "lønn", "lonn", "inntekt", "รายรับ", "เงินเดือน"]
        case .developer:
            ["developer", "development", "software", "app", "code", "coding", "programming", "utvikler", "utvikling", "programmering", "kode", "นักพัฒนา", "ซอฟต์แวร์", "เขียนโค้ด"]
        case .other:
            ["other", "annet", "øvrig", "ovrig", "อื่น"]
        }
    }
}

private extension String {
    var normalizedCategoryKey: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
}
