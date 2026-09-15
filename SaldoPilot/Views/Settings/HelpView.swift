//
//  HelpView.swift
//  SaldoPilot
//
//  Created by Codex on 15/09/2026.
//

import SwiftUI

struct HelpView: View {
    @AppStorage(AppSettingsKey.language) private var languageRawValue = AppLanguage.system.rawValue

    private var article: HelpArticle {
        HelpArticle.article(for: selectedLanguage)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(article.title)
                        .font(.title2.weight(.bold))

                    Text(article.introduction)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            ForEach(article.sections) { section in
                Section(section.title) {
                    ForEach(section.items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.headline)

                            Text(item.body)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
        }
        .navigationTitle(article.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
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
}

private struct HelpArticle {
    let navigationTitle: String
    let title: String
    let introduction: String
    let sections: [HelpSection]

    static func article(for language: AppLanguage) -> HelpArticle {
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

private struct HelpSection: Identifiable {
    let id = UUID()
    let title: String
    let items: [HelpItem]
}

private struct HelpItem: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

private extension HelpArticle {
    static let norwegian = HelpArticle(
        navigationTitle: "Hjelp",
        title: "Brukermanual for SaldoPilot",
        introduction: "SaldoPilot hjelper deg å holde oversikt over inntekter, utgifter, forfall, betalt status og gjentakende poster.",
        sections: [
            HelpSection(
                title: "Oversikt",
                items: [
                    HelpItem(
                        title: "Periode",
                        body: "Velg periode på forsiden for å se summer for ønsket tidsrom. Standardperioden kan endres i Innstillinger."
                    ),
                    HelpItem(
                        title: "Forfalt og neste forfall",
                        body: "Trykk på forfalt eller neste forfall for å åpne Poster med riktig filter."
                    ),
                    HelpItem(
                        title: "Tilgjengelig beløp",
                        body: "I Poster vises tilgjengelig beløp som mottatte inntekter minus betalte utgifter. Grønt betyr pluss, rødt betyr minus."
                    )
                ]
            ),
            HelpSection(
                title: "Poster",
                items: [
                    HelpItem(
                        title: "Ny post",
                        body: "Gå til Poster og trykk på pluss-tegnet øverst. Fyll inn tittel, beløp, type, kategori, forfallsdato og eventuell gjentakelse."
                    ),
                    HelpItem(
                        title: "Betalt eller mottatt",
                        body: "Åpne en post eller bruk handlingene i listen for å registrere betalt dato for utgifter eller mottatt dato for inntekter."
                    ),
                    HelpItem(
                        title: "Gjentakelse",
                        body: "Velg månedlig, kvartalsvis, halvårlig, årlig eller egendefinert intervall. Når en gjentakende post markeres betalt eller mottatt, opprettes neste post automatisk."
                    ),
                    HelpItem(
                        title: "Redigere og slette",
                        body: "Swipe på en post for å redigere, duplisere eller slette. Sletting må bekreftes før posten fjernes."
                    )
                ]
            ),
            HelpSection(
                title: "Filtrering og sortering",
                items: [
                    HelpItem(
                        title: "Hurtigfilter",
                        body: "Bruk filtervalgene øverst i Poster for å vise alle, forfalte, neste forfall, kommende, betalte eller tilgode poster."
                    ),
                    HelpItem(
                        title: "Avanserte filter",
                        body: "Trykk filterikonet øverst for å filtrere på periode, dato-type, status, type, kategori og beløp."
                    ),
                    HelpItem(
                        title: "Sortering",
                        body: "I filtervinduet kan du sortere etter forfallsdato, betalt dato, beløp, tittel, kategori eller status."
                    )
                ]
            ),
            HelpSection(
                title: "Kategorier og språk",
                items: [
                    HelpItem(
                        title: "Kategorier",
                        body: "Kategorier brukes for å organisere postene. Du kan gå til Innstillinger > Kategorier for å se og administrere kategorier."
                    ),
                    HelpItem(
                        title: "Språk",
                        body: "Velg språk i Innstillinger. SaldoPilot støtter norsk, engelsk og thai."
                    )
                ]
            ),
            HelpSection(
                title: "Backup og import",
                items: [
                    HelpItem(
                        title: "Eksport",
                        body: "Bruk Innstillinger > Backup og eksport for å lagre data som JSON eller CSV."
                    ),
                    HelpItem(
                        title: "Import",
                        body: "Bruk Innstillinger > Importer data for å lese inn JSON eller CSV. Ta backup før du importerer større datasett."
                    ),
                    HelpItem(
                        title: "Slette alle poster",
                        body: "I Innstillinger > Administrer kan du slette alle poster. Dette krever bekreftelse."
                    )
                ]
            )
        ]
    )

    static let english = HelpArticle(
        navigationTitle: "Help",
        title: "SaldoPilot User Guide",
        introduction: "SaldoPilot helps you track income, expenses, due dates, paid status, and recurring transactions.",
        sections: [
            HelpSection(
                title: "Overview",
                items: [
                    HelpItem(
                        title: "Period",
                        body: "Choose a period on the overview page to see totals for that range. The default period can be changed in Settings."
                    ),
                    HelpItem(
                        title: "Overdue and next due",
                        body: "Tap overdue or next due to open Transactions with the matching filter."
                    ),
                    HelpItem(
                        title: "Available amount",
                        body: "Transactions shows available amount as received income minus paid expenses. Green means positive, red means negative."
                    )
                ]
            ),
            HelpSection(
                title: "Transactions",
                items: [
                    HelpItem(
                        title: "New transaction",
                        body: "Go to Transactions and tap the plus button at the top. Enter title, amount, type, category, due date, and optional recurrence."
                    ),
                    HelpItem(
                        title: "Paid or received",
                        body: "Open a transaction or use list actions to register a paid date for expenses or a received date for income."
                    ),
                    HelpItem(
                        title: "Recurrence",
                        body: "Choose monthly, quarterly, every six months, yearly, or a custom interval. When a recurring transaction is marked paid or received, the next transaction is created automatically."
                    ),
                    HelpItem(
                        title: "Edit and delete",
                        body: "Swipe a transaction to edit, duplicate, or delete it. Deleting requires confirmation."
                    )
                ]
            ),
            HelpSection(
                title: "Filtering and sorting",
                items: [
                    HelpItem(
                        title: "Quick filters",
                        body: "Use the filter choices at the top of Transactions to show all, overdue, next due, upcoming, paid, or receivable transactions."
                    ),
                    HelpItem(
                        title: "Advanced filters",
                        body: "Tap the filter icon at the top to filter by period, date type, status, type, category, and amount."
                    ),
                    HelpItem(
                        title: "Sorting",
                        body: "In the filter view, you can sort by due date, paid date, amount, title, category, or status."
                    )
                ]
            ),
            HelpSection(
                title: "Categories and language",
                items: [
                    HelpItem(
                        title: "Categories",
                        body: "Categories help organize transactions. Go to Settings > Categories to review and manage categories."
                    ),
                    HelpItem(
                        title: "Language",
                        body: "Choose language in Settings. SaldoPilot supports Norwegian, English, and Thai."
                    )
                ]
            ),
            HelpSection(
                title: "Backup and import",
                items: [
                    HelpItem(
                        title: "Export",
                        body: "Use Settings > Backup and export to save your data as JSON or CSV."
                    ),
                    HelpItem(
                        title: "Import",
                        body: "Use Settings > Import data to read JSON or CSV. Take a backup before importing larger data sets."
                    ),
                    HelpItem(
                        title: "Delete all transactions",
                        body: "In Settings > Manage, you can delete all transactions. This requires confirmation."
                    )
                ]
            )
        ]
    )

    static let thai = HelpArticle(
        navigationTitle: "ช่วยเหลือ",
        title: "คู่มือการใช้งาน SaldoPilot",
        introduction: "SaldoPilot ช่วยติดตามรายรับ รายจ่าย วันครบกำหนด สถานะการชำระเงิน และรายการที่เกิดซ้ำ",
        sections: [
            HelpSection(
                title: "ภาพรวม",
                items: [
                    HelpItem(
                        title: "ช่วงเวลา",
                        body: "เลือกช่วงเวลาบนหน้าภาพรวมเพื่อดูยอดรวมของช่วงนั้น สามารถเปลี่ยนช่วงเวลาเริ่มต้นได้ในตั้งค่า"
                    ),
                    HelpItem(
                        title: "ค้างชำระและครบกำหนดถัดไป",
                        body: "แตะค้างชำระหรือครบกำหนดถัดไปเพื่อเปิดรายการพร้อมตัวกรองที่เกี่ยวข้อง"
                    ),
                    HelpItem(
                        title: "ยอดที่ใช้ได้",
                        body: "หน้า รายการ จะแสดงยอดที่ใช้ได้จากรายรับที่ได้รับแล้วลบด้วยรายจ่ายที่ชำระแล้ว สีเขียวหมายถึงยอดบวก สีแดงหมายถึงยอดติดลบ"
                    )
                ]
            ),
            HelpSection(
                title: "รายการ",
                items: [
                    HelpItem(
                        title: "รายการใหม่",
                        body: "ไปที่ รายการ แล้วแตะปุ่มบวกด้านบน ใส่ชื่อ จำนวนเงิน ประเภท หมวดหมู่ วันครบกำหนด และการเกิดซ้ำถ้ามี"
                    ),
                    HelpItem(
                        title: "ชำระแล้วหรือได้รับแล้ว",
                        body: "เปิดรายการหรือใช้การกระทำในลิสต์เพื่อลงวันที่ชำระเงินสำหรับรายจ่าย หรือวันที่ได้รับเงินสำหรับรายรับ"
                    ),
                    HelpItem(
                        title: "การเกิดซ้ำ",
                        body: "เลือกทุกเดือน ทุกไตรมาส ทุกหกเดือน ทุกปี หรือช่วงเวลาที่กำหนดเอง เมื่อรายการที่เกิดซ้ำถูกทำเครื่องหมายว่าชำระแล้วหรือได้รับแล้ว ระบบจะสร้างรายการถัดไปให้อัตโนมัติ"
                    ),
                    HelpItem(
                        title: "แก้ไขและลบ",
                        body: "ปัดรายการเพื่อแก้ไข ทำสำเนา หรือลบ การลบต้องยืนยันก่อนเสมอ"
                    )
                ]
            ),
            HelpSection(
                title: "ตัวกรองและการเรียง",
                items: [
                    HelpItem(
                        title: "ตัวกรองด่วน",
                        body: "ใช้ตัวเลือกด้านบนของหน้า รายการ เพื่อแสดงทั้งหมด ค้างชำระ ครบกำหนดถัดไป รายการที่จะมาถึง ชำระแล้ว หรือรายรับที่รอดำเนินการ"
                    ),
                    HelpItem(
                        title: "ตัวกรองขั้นสูง",
                        body: "แตะไอคอนตัวกรองด้านบนเพื่อกรองตามช่วงเวลา ประเภทวันที่ สถานะ ประเภท หมวดหมู่ และจำนวนเงิน"
                    ),
                    HelpItem(
                        title: "การเรียงลำดับ",
                        body: "ในหน้าตัวกรอง คุณสามารถเรียงตามวันครบกำหนด วันที่ชำระ จำนวนเงิน ชื่อ หมวดหมู่ หรือสถานะ"
                    )
                ]
            ),
            HelpSection(
                title: "หมวดหมู่และภาษา",
                items: [
                    HelpItem(
                        title: "หมวดหมู่",
                        body: "หมวดหมู่ช่วยจัดระเบียบรายการ ไปที่ ตั้งค่า > หมวดหมู่ เพื่อดูและจัดการหมวดหมู่"
                    ),
                    HelpItem(
                        title: "ภาษา",
                        body: "เลือกภาษาในตั้งค่า SaldoPilot รองรับนอร์เวย์ อังกฤษ และไทย"
                    )
                ]
            ),
            HelpSection(
                title: "สำรองข้อมูลและนำเข้า",
                items: [
                    HelpItem(
                        title: "ส่งออก",
                        body: "ใช้ ตั้งค่า > สำรองข้อมูลและส่งออก เพื่อบันทึกข้อมูลเป็น JSON หรือ CSV"
                    ),
                    HelpItem(
                        title: "นำเข้า",
                        body: "ใช้ ตั้งค่า > นำเข้าข้อมูล เพื่ออ่านไฟล์ JSON หรือ CSV ควรสำรองข้อมูลก่อนนำเข้าชุดข้อมูลขนาดใหญ่"
                    ),
                    HelpItem(
                        title: "ลบทุกรายการ",
                        body: "ใน ตั้งค่า > จัดการ คุณสามารถลบทุกรายการได้ การลบต้องยืนยันก่อน"
                    )
                ]
            )
        ]
    )
}

#Preview {
    NavigationStack {
        HelpView()
    }
}
