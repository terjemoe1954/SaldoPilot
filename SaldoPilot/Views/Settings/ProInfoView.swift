//
//  ProInfoView.swift
//  SaldoPilot
//
//  Created by Codex on 19/09/2026.
//

import StoreKit
import SwiftUI

struct ProInfoView: View {
    @Environment(ProPurchaseStore.self) private var proPurchaseStore
    @AppStorage(AppSettingsKey.language) private var languageRawValue = AppLanguage.system.rawValue

    private var content: ProInfoContent {
        ProInfoContent.content(for: selectedLanguage)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label(content.title, systemImage: "star.circle.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)

                    Text(content.introduction)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section(content.currentStatusTitle) {
                LabeledContent(content.statusLabel, value: statusText)
                if let price = proPurchaseStore.product?.displayPrice {
                    LabeledContent(content.priceLabel, value: price)
                }

                if proPurchaseStore.isLoading {
                    ProgressView()
                }

                if !proPurchaseStore.isProUnlocked {
                    Button {
                        Task {
                            await proPurchaseStore.purchasePro()
                        }
                    } label: {
                        Label(purchaseButtonTitle, systemImage: "cart")
                    }
                    .disabled(proPurchaseStore.product == nil || proPurchaseStore.isLoading)
                }

                Button {
                    Task {
                        await proPurchaseStore.restorePurchases()
                    }
                } label: {
                    Label(content.restoreButtonTitle, systemImage: "arrow.clockwise")
                }
                .disabled(proPurchaseStore.isLoading)

                if let message = proPurchaseStore.message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else if proPurchaseStore.product == nil {
                    Text(content.productUnavailableText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section(content.freeTitle) {
                ForEach(content.freeFeatures) { feature in
                    ProFeatureRow(feature: feature, systemImage: "checkmark.circle")
                }
            }

            Section(content.proTitle) {
                ForEach(content.proFeatures) { feature in
                    ProFeatureRow(feature: feature, systemImage: "sparkles")
                }
            }

            Section(content.storeKitTitle) {
                ForEach(content.storeKitNotes) { note in
                    ProFeatureRow(feature: note, systemImage: "cart")
                }
            }
        }
        .navigationTitle("SaldoPilot Pro")
        .task {
            await proPurchaseStore.refresh()
        }
    }

    private var selectedLanguage: AppLanguage {
        let language = AppLanguage(rawValue: languageRawValue) ?? .system
        guard language == .system else { return language }

        let identifier = Locale.autoupdatingCurrent.identifier.lowercased()
        if identifier.hasPrefix("th") {
            return .thai
        }

        if identifier.hasPrefix("nb") || identifier.hasPrefix("nn") || identifier.hasPrefix("no") {
            return .norwegian
        }

        return .english
    }

    private var statusText: String {
        proPurchaseStore.isProUnlocked ? content.proStatus : content.freeStatus
    }

    private var purchaseButtonTitle: String {
        if let price = proPurchaseStore.product?.displayPrice {
            return "\(content.purchaseButtonTitle) \(price)"
        }

        return content.purchaseButtonTitle
    }
}

private struct ProFeatureRow: View {
    let feature: ProInfoFeature
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.subheadline.weight(.semibold))
                Text(feature.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
        }
        .padding(.vertical, 2)
    }
}

private struct ProInfoFeature: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

private struct ProInfoContent {
    let title: String
    let introduction: String
    let currentStatusTitle: String
    let statusLabel: String
    let freeStatus: String
    let proStatus: String
    let priceLabel: String
    let purchaseButtonTitle: String
    let restoreButtonTitle: String
    let productUnavailableText: String
    let freeTitle: String
    let freeFeatures: [ProInfoFeature]
    let proTitle: String
    let proFeatures: [ProInfoFeature]
    let storeKitTitle: String
    let storeKitNotes: [ProInfoFeature]

    static func content(for language: AppLanguage) -> ProInfoContent {
        switch language {
        case .norwegian:
            norwegian
        case .thai:
            thai
        case .system, .english:
            english
        }
    }
}

private extension ProInfoContent {
    static let norwegian = ProInfoContent(
        title: "SaldoPilot Pro",
        introduction: "Pro-grunnlaget er på plass slik at betalte funksjoner kan planlegges ryddig før kjøp aktiveres.",
        currentStatusTitle: "Status",
        statusLabel: "Nåværende plan",
        freeStatus: "Gratis",
        proStatus: "SaldoPilot Pro",
        priceLabel: "Pris",
        purchaseButtonTitle: "Kjøp Pro",
        restoreButtonTitle: "Gjenopprett kjøp",
        productUnavailableText: "SaldoPilot Pro er ikke tilgjengelig fra App Store ennå. Kontroller produktet i App Store Connect eller StoreKit-testing.",
        freeTitle: "Gratis basisapp",
        freeFeatures: [
            ProInfoFeature(title: "Poster", detail: "Opprett inntekter og utgifter med status, kategori, dato og notat."),
            ProInfoFeature(title: "Gjentakelser", detail: "Lag neste post automatisk når faste inntekter eller utgifter betales eller mottas."),
            ProInfoFeature(title: "Oversikt og statistikk", detail: "Se forfalt, neste forfall, til gode, netto og enkle grafer."),
            ProInfoFeature(title: "Backup og import", detail: "Eksporter og importer data med JSON og CSV.")
        ],
        proTitle: "Mulige Pro-funksjoner",
        proFeatures: [
            ProInfoFeature(title: "Budsjett per kategori", detail: "Planlegg grenser og se når en kategori nærmer seg budsjett."),
            ProInfoFeature(title: "Prognose", detail: "Beregn forventet månedsslutt basert på kommende inntekter og utgifter."),
            ProInfoFeature(title: "Smarte forslag", detail: "Foreslå kategori, gjentakelse og nyttige handlinger basert på historikk."),
            ProInfoFeature(title: "Avansert eksport", detail: "Flere valg for eksport og rapportering.")
        ],
        storeKitTitle: "StoreKit-plan",
        storeKitNotes: [
            ProInfoFeature(title: "Engangskjøp", detail: "SaldoPilot Pro er satt opp som ett kjøp på 39 kr."),
            ProInfoFeature(title: "Ingen låsing ennå", detail: "Kjøpsstatus er koblet til appen, men funksjoner låses ikke før Pro-grensen er endelig testet.")
        ]
    )

    static let english = ProInfoContent(
        title: "SaldoPilot Pro",
        introduction: "The Pro foundation is in place so paid features can be planned clearly before purchases are enabled.",
        currentStatusTitle: "Status",
        statusLabel: "Current plan",
        freeStatus: "Free",
        proStatus: "SaldoPilot Pro",
        priceLabel: "Price",
        purchaseButtonTitle: "Buy Pro",
        restoreButtonTitle: "Restore purchases",
        productUnavailableText: "SaldoPilot Pro is not available from the App Store yet. Check the product in App Store Connect or StoreKit testing.",
        freeTitle: "Free base app",
        freeFeatures: [
            ProInfoFeature(title: "Transactions", detail: "Create income and expenses with status, category, date and notes."),
            ProInfoFeature(title: "Recurring items", detail: "Create the next item automatically when fixed income or expenses are paid or received."),
            ProInfoFeature(title: "Overview and statistics", detail: "See overdue items, next due date, receivables, net amount and simple charts."),
            ProInfoFeature(title: "Backup and import", detail: "Export and import data with JSON and CSV.")
        ],
        proTitle: "Possible Pro features",
        proFeatures: [
            ProInfoFeature(title: "Budgets by category", detail: "Plan limits and see when a category is close to its budget."),
            ProInfoFeature(title: "Forecast", detail: "Estimate month-end status from upcoming income and expenses."),
            ProInfoFeature(title: "Smart suggestions", detail: "Suggest category, recurrence and useful actions from history."),
            ProInfoFeature(title: "Advanced export", detail: "More choices for export and reporting.")
        ],
        storeKitTitle: "StoreKit plan",
        storeKitNotes: [
            ProInfoFeature(title: "One-time purchase", detail: "SaldoPilot Pro is set up as one purchase for 39 kr."),
            ProInfoFeature(title: "No locking yet", detail: "Purchase status is connected to the app, but features are not locked until the Pro boundary is fully tested.")
        ]
    )

    static let thai = ProInfoContent(
        title: "SaldoPilot Pro",
        introduction: "วางพื้นฐาน Pro ไว้เพื่อให้วางแผนฟีเจอร์แบบชำระเงินได้ชัดเจน ก่อนเปิดใช้การซื้อ",
        currentStatusTitle: "สถานะ",
        statusLabel: "แผนปัจจุบัน",
        freeStatus: "ฟรี",
        proStatus: "SaldoPilot Pro",
        priceLabel: "ราคา",
        purchaseButtonTitle: "ซื้อ Pro",
        restoreButtonTitle: "กู้คืนการซื้อ",
        productUnavailableText: "SaldoPilot Pro ยังไม่พร้อมใช้งานจาก App Store โปรดตรวจสอบสินค้าใน App Store Connect หรือการทดสอบ StoreKit",
        freeTitle: "แอปพื้นฐานฟรี",
        freeFeatures: [
            ProInfoFeature(title: "รายการ", detail: "สร้างรายรับและรายจ่ายพร้อมสถานะ หมวดหมู่ วันที่ และบันทึก"),
            ProInfoFeature(title: "รายการที่เกิดซ้ำ", detail: "สร้างรายการถัดไปอัตโนมัติเมื่อจ่ายหรือรับเงินรายการประจำ"),
            ProInfoFeature(title: "ภาพรวมและสถิติ", detail: "ดูรายการค้างชำระ วันครบกำหนดถัดไป เงินที่รอรับ ยอดสุทธิ และกราฟพื้นฐาน"),
            ProInfoFeature(title: "สำรองข้อมูลและนำเข้า", detail: "ส่งออกและนำเข้าข้อมูลด้วย JSON และ CSV")
        ],
        proTitle: "ฟีเจอร์ Pro ที่เป็นไปได้",
        proFeatures: [
            ProInfoFeature(title: "งบประมาณตามหมวดหมู่", detail: "วางแผนวงเงินและดูเมื่อหมวดหมู่ใกล้ถึงงบประมาณ"),
            ProInfoFeature(title: "การคาดการณ์", detail: "ประเมินสถานะปลายเดือนจากรายรับและรายจ่ายที่กำลังจะมาถึง"),
            ProInfoFeature(title: "คำแนะนำอัจฉริยะ", detail: "แนะนำหมวดหมู่ การเกิดซ้ำ และการทำงานที่เหมาะสมจากประวัติ"),
            ProInfoFeature(title: "การส่งออกขั้นสูง", detail: "ตัวเลือกเพิ่มเติมสำหรับการส่งออกและรายงาน")
        ],
        storeKitTitle: "แผน StoreKit",
        storeKitNotes: [
            ProInfoFeature(title: "ซื้อครั้งเดียว", detail: "SaldoPilot Pro ตั้งค่าเป็นการซื้อครั้งเดียวราคา 39 kr"),
            ProInfoFeature(title: "ยังไม่ล็อกฟีเจอร์", detail: "เชื่อมสถานะการซื้อกับแอปแล้ว แต่ยังไม่ล็อกฟีเจอร์จนกว่าจะทดสอบขอบเขต Pro เรียบร้อย")
        ]
    )
}

#Preview {
    NavigationStack {
        ProInfoView()
    }
    .environment(ProPurchaseStore())
}
