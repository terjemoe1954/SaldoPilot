//
//  Category.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import SwiftUI

enum CategoryKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case clothing
    case communication
    case deduction
    case developer
    case entertainment
    case payrollDeduction
    case gifts
    case groceries
    case health
    case home
    case income
    case insurance
    case other
    case savings
    case subscriptions
    case transport

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .clothing:
            "Clothing"
        case .communication:
            "Communication"
        case .deduction:
            "Deduction"
        case .developer:
            "Developer"
        case .entertainment:
            "Entertainment"
        case .payrollDeduction:
            "Gambling"
        case .gifts:
            "Gifts"
        case .groceries:
            "Groceries"
        case .health:
            "Health"
        case .home:
            "Home"
        case .income:
            "Income"
        case .insurance:
            "Insurance"
        case .other:
            "Other"
        case .savings:
            "Savings"
        case .subscriptions:
            "Subscriptions"
        case .transport:
            "Transport"
        }
    }

    var systemImage: String {
        switch self {
        case .clothing:
            "tshirt"
        case .communication:
            "phone"
        case .deduction:
            "minus.circle"
        case .developer:
            "curlybraces"
        case .entertainment:
            "popcorn"
        case .payrollDeduction:
            "dice"
        case .gifts:
            "gift"
        case .groceries:
            "cart"
        case .health:
            "cross.case"
        case .home:
            "house"
        case .income:
            "arrow.down.circle"
        case .insurance:
            "shield"
        case .other:
            "tag"
        case .savings:
            "banknote"
        case .subscriptions:
            "repeat"
        case .transport:
            "car"
        }
    }

    var tint: Color {
        switch self {
        case .clothing:
            .pink
        case .communication:
            .teal
        case .deduction:
            .brown
        case .developer:
            .black
        case .entertainment:
            .yellow
        case .payrollDeduction:
            .red
        case .gifts:
            .purple
        case .groceries:
            .green
        case .health:
            .red
        case .home:
            .blue
        case .income:
            .green
        case .insurance:
            .indigo
        case .other:
            .gray
        case .savings:
            .mint
        case .subscriptions:
            .purple
        case .transport:
            .orange
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

    static func sortedForDisplay(locale: Locale) -> [CategoryKind] {
        allCases.sorted {
            $0.localizedTitle(locale: locale).localizedCaseInsensitiveCompare($1.localizedTitle(locale: locale)) == .orderedAscending
        }
    }

    func localizedTitle(locale: Locale) -> String {
        let identifier = locale.identifier.lowercased()

        if identifier.hasPrefix("nb") || identifier.hasPrefix("nn") || identifier.hasPrefix("no") {
            return norwegianTitle
        }

        if identifier.hasPrefix("th") {
            return thaiTitle
        }

        return englishTitle
    }

    private var englishTitle: String {
        switch self {
        case .clothing:
            "Clothing"
        case .communication:
            "Communication"
        case .deduction:
            "Deduction"
        case .developer:
            "Developer"
        case .entertainment:
            "Entertainment"
        case .payrollDeduction:
            "Gambling"
        case .gifts:
            "Gifts"
        case .groceries:
            "Groceries"
        case .health:
            "Health"
        case .home:
            "Home"
        case .income:
            "Income"
        case .insurance:
            "Insurance"
        case .other:
            "Other"
        case .savings:
            "Savings"
        case .subscriptions:
            "Subscriptions"
        case .transport:
            "Transport"
        }
    }

    private var norwegianTitle: String {
        switch self {
        case .clothing:
            "Klær"
        case .communication:
            "Kommunikasjon"
        case .deduction:
            "Trekk"
        case .developer:
            "Utvikler"
        case .entertainment:
            "Underholdning"
        case .payrollDeduction:
            "Pengespill"
        case .gifts:
            "Gaver"
        case .groceries:
            "Dagligvarer"
        case .health:
            "Helse"
        case .home:
            "Hjem"
        case .income:
            "Inntekt"
        case .insurance:
            "Forsikring"
        case .other:
            "Annet"
        case .savings:
            "Sparing"
        case .subscriptions:
            "Abonnementer"
        case .transport:
            "Transport"
        }
    }

    private var thaiTitle: String {
        switch self {
        case .clothing:
            "เสื้อผ้า"
        case .communication:
            "การสื่อสาร"
        case .deduction:
            "การหักเงิน"
        case .developer:
            "นักพัฒนา"
        case .entertainment:
            "บันเทิง"
        case .payrollDeduction:
            "การพนัน"
        case .gifts:
            "ของขวัญ"
        case .groceries:
            "ของชำ"
        case .health:
            "สุขภาพ"
        case .home:
            "บ้าน"
        case .income:
            "รายรับ"
        case .insurance:
            "ประกัน"
        case .other:
            "อื่น"
        case .savings:
            "เงินออม"
        case .subscriptions:
            "การสมัครสมาชิก"
        case .transport:
            "การเดินทาง"
        }
    }

    func matches(transactionTitle: String) -> Bool {
        let normalizedTitle = transactionTitle.normalizedCategoryKey
        return searchTerms.contains { normalizedTitle.contains($0.normalizedCategoryKey) }
    }

    private var searchTerms: [String] {
        switch self {
        case .clothing:
            ["clothing", "clothes", "shoes", "klær", "klaer", "sko", "เสื้อผ้า", "รองเท้า"]
        case .communication:
            ["communication", "phone", "mobile", "internet", "mobil", "telefon", "โทรศัพท์", "อินเทอร์เน็ต"]
        case .deduction:
            ["deduction", "deductions", "withholding", "payroll deduction", "wage garnishment", "garnishment", "attachment of earnings", "trekk", "påleggstrekk", "paleggstrekk", "utleggstrekk", "fradrag", "การหักเงินเดือน", "หักเงินเดือน", "หักเงินเดือนตามคำสั่ง"]
        case .developer:
            ["developer", "development", "software", "app", "code", "coding", "programming", "utvikler", "utvikling", "programmering", "kode", "นักพัฒนา", "ซอฟต์แวร์", "เขียนโค้ด"]
        case .entertainment:
            ["entertainment", "movie", "cinema", "game", "restaurant", "underholdning", "kino", "spill", "บันเทิง"]
        case .payrollDeduction:
            ["gambling", "casino", "betting", "bet", "lottery", "lotto", "spill", "pengespill", "casino", "tipping", "พนัน", "คาสิโน", "ลอตเตอรี่"]
        case .gifts:
            ["gift", "gifts", "present", "presents", "gave", "gaver", "presang", "ของขวัญ"]
        case .groceries:
            ["groceries", "grocery", "food", "supermarket", "mat", "dagligvarer", "butikk", "อาหาร", "ของชำ"]
        case .health:
            ["health", "doctor", "pharmacy", "medicine", "helse", "lege", "apotek", "สุขภาพ", "ยา"]
        case .home:
            ["home", "housing", "rent", "mortgage", "electricity", "power", "bolig", "husleie", "strom", "strøm", "บ้าน", "ค่าเช่า"]
        case .income:
            ["income", "salary", "wage", "lønn", "lonn", "inntekt", "รายรับ", "เงินเดือน"]
        case .insurance:
            ["insurance", "forsikring", "ประกัน"]
        case .other:
            ["other", "annet", "øvrig", "ovrig", "อื่น"]
        case .savings:
            ["savings", "saving", "save", "spare", "sparing", "ออม", "เงินออม"]
        case .subscriptions:
            ["subscription", "subscriptions", "netflix", "spotify", "abonnement", "สมาชิก"]
        case .transport:
            ["transport", "car", "bus", "train", "taxi", "fuel", "bensin", "bil", "transport", "รถ", "เดินทาง"]
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
