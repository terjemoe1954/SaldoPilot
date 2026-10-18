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
    case diningOut
    case entertainment
    case payrollDeduction
    case gifts
    case groceries
    case health
    case home
    case income
    case insurance
    case other
    case refund
    case savings
    case subscriptions
    case transport

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .clothing:
            "Clothing & shoes"
        case .communication:
            "Phone & internet"
        case .deduction:
            "Taxes & fees"
        case .developer:
            "Hobby & development"
        case .diningOut:
            "Dining out"
        case .entertainment:
            "Leisure & travel"
        case .payrollDeduction:
            "Gambling"
        case .gifts:
            "Gifts"
        case .groceries:
            "Groceries"
        case .health:
            "Health"
        case .home:
            "Housing & electricity"
        case .income:
            "Salary & income"
        case .insurance:
            "Insurance"
        case .other:
            "Other"
        case .refund:
            "Refund"
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
        case .diningOut:
            "fork.knife"
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
        case .refund:
            "arrow.uturn.backward.circle"
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
        case .diningOut:
            .orange
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
        case .refund:
            .cyan
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

        if let exactMatch = allCases.first(where: { category in
            [
                category.rawValue,
                category.englishTitle,
                category.norwegianTitle,
                category.thaiTitle
            ].contains { $0.normalizedCategoryKey == normalizedValue }
        }) {
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
            "Clothing & shoes"
        case .communication:
            "Phone & internet"
        case .deduction:
            "Taxes & fees"
        case .developer:
            "Hobby & development"
        case .diningOut:
            "Dining out"
        case .entertainment:
            "Leisure & travel"
        case .payrollDeduction:
            "Gambling"
        case .gifts:
            "Gifts"
        case .groceries:
            "Groceries"
        case .health:
            "Health"
        case .home:
            "Housing & electricity"
        case .income:
            "Salary & income"
        case .insurance:
            "Insurance"
        case .other:
            "Other"
        case .refund:
            "Refund"
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
            "Klær & sko"
        case .communication:
            "Telefon & internett"
        case .deduction:
            "Skatt & avgifter"
        case .developer:
            "Hobby & Utvikling"
        case .diningOut:
            "Spise ute"
        case .entertainment:
            "Fritid & ferie"
        case .payrollDeduction:
            "Pengespill"
        case .gifts:
            "Gaver"
        case .groceries:
            "Dagligvarer"
        case .health:
            "Helse"
        case .home:
            "Bolig & strøm"
        case .income:
            "Lønn & Inntekt"
        case .insurance:
            "Forsikring"
        case .other:
            "Annet"
        case .refund:
            "Refusjon"
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
            "เสื้อผ้าและรองเท้า"
        case .communication:
            "โทรศัพท์และอินเทอร์เน็ต"
        case .deduction:
            "ภาษีและค่าธรรมเนียม"
        case .developer:
            "งานอดิเรกและการพัฒนา"
        case .diningOut:
            "รับประทานอาหารนอกบ้าน"
        case .entertainment:
            "สันทนาการและวันหยุด"
        case .payrollDeduction:
            "การพนัน"
        case .gifts:
            "ของขวัญ"
        case .groceries:
            "ของชำ"
        case .health:
            "สุขภาพ"
        case .home:
            "ที่อยู่อาศัยและค่าไฟ"
        case .income:
            "เงินเดือนและรายรับ"
        case .insurance:
            "ประกัน"
        case .other:
            "อื่น"
        case .refund:
            "การคืนเงิน"
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
            ["communication", "phone", "mobile", "internet", "tv package", "kommunikasjon", "mobil", "telefon", "internett", "tv-pakke", "tvpakke", "โทรศัพท์", "อินเทอร์เน็ต"]
        case .deduction:
            ["deduction", "deductions", "tax", "taxes", "fee", "fees", "back tax", "withholding", "payroll deduction", "wage garnishment", "garnishment", "attachment of earnings", "trekk", "skatt", "avgift", "avgifter", "restskatt", "påleggstrekk", "paleggstrekk", "utleggstrekk", "fradrag", "การหักเงินเดือน", "หักเงินเดือน", "หักเงินเดือนตามคำสั่ง"]
        case .developer:
            ["developer", "development", "app development", "hobby", "software", "chatgpt", "openai", "app store connect", "xcode", "code", "coding", "programming", "utvikler", "apputvikling", "hobby og utvikling", "utvikling", "programmering", "kode", "นักพัฒนา", "ซอฟต์แวร์", "เขียนโค้ด"]
        case .diningOut:
            ["dining out", "restaurant", "cafe", "café", "takeaway", "take away", "fast food", "burger king", "mcdonald", "hamburger", "spise ute", "restaurant", "kafe", "kafé", "gatekjøkken", "ferdigmat kjøpt ute", "ร้านอาหาร", "คาเฟ่", "อาหารจานด่วน"]
        case .entertainment:
            ["entertainment", "leisure", "holiday", "vacation", "travel", "movie", "cinema", "game", "underholdning", "fritid", "ferie", "kino", "spill", "บันเทิง"]
        case .payrollDeduction:
            ["gambling", "casino", "betting", "bet", "lottery", "lotto", "spill", "pengespill", "casino", "tipping", "พนัน", "คาสิโน", "ลอตเตอรี่"]
        case .gifts:
            ["gift", "gifts", "present", "presents", "gave", "gaver", "presang", "ของขวัญ"]
        case .groceries:
            ["groceries", "grocery", "food", "supermarket", "mat", "dagligvarer", "butikk", "อาหาร", "ของชำ"]
        case .health:
            ["health", "doctor", "pharmacy", "medicine", "helse", "lege", "apotek", "สุขภาพ", "ยา"]
        case .home:
            ["home", "housing", "rent", "mortgage", "electricity", "power", "hjem", "bolig", "husleie", "strom", "strøm", "บ้าน", "ค่าเช่า"]
        case .income:
            ["income", "incomes", "salary", "wage", "lønn", "lonn", "inntekt", "inntekter", "รายรับ", "เงินเดือน"]
        case .insurance:
            ["insurance", "forsikring", "ประกัน"]
        case .other:
            ["other", "annet", "øvrig", "ovrig", "อื่น"]
        case .refund:
            ["refund", "reimbursement", "refunded", "cashback", "refusjon", "tilbakebetaling", "tilbakebetalt", "คืนเงิน", "การคืนเงิน"]
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
