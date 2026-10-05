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
                        VStack(alignment: .leading, spacing: 6) {
                            Label(item.title, systemImage: item.systemImage)
                                .font(.headline)

                            Text(item.body)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 4)
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
    let systemImage: String
    let body: String
}

private extension HelpArticle {
    static let norwegian = HelpArticle(
        navigationTitle: "Brukermanual",
        title: "Brukermanual for SaldoPilot",
        introduction: "SaldoPilot hjelper deg å planlegge inntekter og utgifter, følge med på forfall, registrere betalte regninger og mottatt lønn, og lage neste post automatisk når noe gjentar seg.",
        sections: [
            HelpSection(
                title: "Kom i gang",
                items: [
                    HelpItem(
                        title: "Grunntanken",
                        systemImage: "lightbulb",
                        body: "Legg inn alle faste inntekter og utgifter som poster. En post starter vanligvis som ventende. Når regningen er betalt eller lønnen er mottatt, åpner du posten og registrerer datoen. Da flyttes posten til betalt/mottatt status."
                    ),
                    HelpItem(
                        title: "Forsiden",
                        systemImage: "gauge.with.dots.needle.33percent",
                        body: "Oversikt viser saldo, inntekter, utgifter, forfalte poster, neste forfall og ventende inntekter for valgt periode. Trykk på forfalt, neste forfall eller ventende inntekt for å åpne Poster med riktig filter."
                    ),
                    HelpItem(
                        title: "Periode",
                        systemImage: "calendar",
                        body: "Fra og til på forsiden bestemmer hvilke poster som tas med i summer og statistikk. I Innstillinger kan du velge standardperiode, for eksempel denne måneden."
                    )
                ]
            ),
            HelpSection(
                title: "Opprette poster",
                items: [
                    HelpItem(
                        title: "Registrere en regning eller utgift",
                        systemImage: "minus.circle",
                        body: "Gå til Poster og trykk pluss øverst. Velg type Utgift, skriv navn, beløp, kategori og forfallsdato. Velg gjentakelse hvis regningen kommer fast, for eksempel hver måned."
                    ),
                    HelpItem(
                        title: "Registrere lønn eller inntekt",
                        systemImage: "plus.circle",
                        body: "Gå til Poster og trykk pluss øverst. Velg type Inntekt, legg inn beløp, kategori og datoen pengene forventes mottatt. For lønn bør du velge månedlig gjentakelse hvis den kommer fast."
                    ),
                    HelpItem(
                        title: "Kategorier",
                        systemImage: "tag",
                        body: "Kategorier gjør det lettere å lese statistikk og finne poster senere. Velg den kategorien som passer best, for eksempel Lønn, Husleie, Mat, Gaver, Trekk eller Pengespill."
                    ),
                    HelpItem(
                        title: "Notater",
                        systemImage: "note.text",
                        body: "Bruk notatfeltet til praktiske detaljer, for eksempel kidnummer, kontonummer, avtaleinformasjon eller andre ting du vil huske om posten."
                    )
                ]
            ),
            HelpSection(
                title: "Betale og godkjenne",
                items: [
                    HelpItem(
                        title: "Registrere betalt regning",
                        systemImage: "checkmark.circle",
                        body: "Når en regning er betalt i banken, åpner du posten fra Poster. Velg registrer betalt dato og lagre. Posten får status Betalt, og betalt dato brukes i filter, oversikt og statistikk."
                    ),
                    HelpItem(
                        title: "Registrere mottatt lønn eller inntekt",
                        systemImage: "banknote",
                        body: "Når lønn, pensjon eller annen inntekt er kommet inn på konto, åpner du inntektsposten. Registrer mottatt dato og lagre. Posten får status Mottatt."
                    ),
                    HelpItem(
                        title: "Gjentakende poster",
                        systemImage: "repeat",
                        body: "Hvis posten har gjentakelse, opprettes neste post automatisk når du markerer den som Betalt eller Mottatt. Den nye posten får ny forfallsdato basert på intervallet du valgte."
                    ),
                    HelpItem(
                        title: "Hva skjer med oppgjorte poster",
                        systemImage: "tray.full",
                        body: "Betalte og mottatte poster kan skjules fra vanlig postliste med valget Vis oppgjorte poster i Innstillinger. De kan fortsatt vises med filteret Betalt/Mottatt."
                    )
                ]
            ),
            HelpSection(
                title: "Poster-listen",
                items: [
                    HelpItem(
                        title: "Finne riktig post",
                        systemImage: "line.3.horizontal.decrease.circle",
                        body: "Bruk hurtigfiltrene øverst for alle, forfalt, neste forfall, kommende, betalt eller tilgode. Filterknappen gir flere valg som periode, dato-type, status, type, kategori og beløp."
                    ),
                    HelpItem(
                        title: "Sortering",
                        systemImage: "arrow.up.arrow.down",
                        body: "I filtervinduet kan du sortere etter forfallsdato, betalt dato, beløp, tittel, kategori eller status. Dette er nyttig når du skal betale flere regninger på samme dag."
                    ),
                    HelpItem(
                        title: "Redigere, duplisere og slette",
                        systemImage: "slider.horizontal.3",
                        body: "Sveip på en post for handlinger. Rediger brukes når noe skal endres. Dupliser er nyttig for lignende poster. Sletting må bekreftes før posten fjernes."
                    ),
                    HelpItem(
                        title: "Tilgjengelig beløp",
                        systemImage: "creditcard",
                        body: "Øverst i Poster vises et kapsel-felt med tilgjengelig beløp. Grønt betyr at mottatte inntekter er større enn betalte utgifter. Rødt betyr minus."
                    )
                ]
            ),
            HelpSection(
                title: "Oversikt og statistikk",
                items: [
                    HelpItem(
                        title: "Oversikt",
                        systemImage: "chart.pie",
                        body: "Forsiden er laget for rask kontroll: hva har kommet inn, hva er betalt, hva forfaller snart, og hva mangler. Bruk den før du betaler regninger."
                    ),
                    HelpItem(
                        title: "Statistikk",
                        systemImage: "chart.bar.xaxis",
                        body: "Statistikk viser blant annet utgifter per kategori og antall transaksjoner. Dette gjør det lettere å se hvor pengene går i valgt periode."
                    ),
                    HelpItem(
                        title: "AI-oppsummering",
                        systemImage: "sparkles",
                        body: "AI-oppsummering kan forklare tallene i perioden med enkel tekst. Ekstern AI kan slås av eller på i Innstillinger, avhengig av hva du ønsker å bruke."
                    )
                ]
            ),
            HelpSection(
                title: "Varsler",
                items: [
                    HelpItem(
                        title: "Slå på varsler",
                        systemImage: "bell",
                        body: "Gå til Innstillinger > Varsler og slå på det du vil bruke: forfall i dag, forfall i morgen, forfall på forhånd eller ventende inntekt. iOS må også ha gitt SaldoPilot tillatelse til varsler."
                    ),
                    HelpItem(
                        title: "Tidspunkt",
                        systemImage: "clock",
                        body: "Vanlige forfallsvarsler kommer kl. 09:00. Forfalte utgifter og ventende inntekter varsles kl. 18:00. Hvis du tester forfall i dag etter kl. 09:00, kan appen legge et testnært varsel omtrent ett minutt frem i tid."
                    )
                ]
            ),
            HelpSection(
                title: "Innstillinger og sikkerhet",
                items: [
                    HelpItem(
                        title: "Språk og utseende",
                        systemImage: "globe",
                        body: "I Innstillinger kan du velge norsk, engelsk, thai eller systemets språk. Du kan også velge lys, mørk eller systemstyrt visning."
                    ),
                    HelpItem(
                        title: "Backup og eksport",
                        systemImage: "externaldrive",
                        body: "Bruk Backup og eksport for å lagre data som JSON eller CSV. JSON er best for full backup. CSV er nyttig hvis du vil se data i Numbers eller Excel."
                    ),
                    HelpItem(
                        title: "Import",
                        systemImage: "square.and.arrow.down",
                        body: "Bruk Importer data for å lese inn tidligere eksport. Ta alltid backup før import, spesielt hvis du allerede har mange poster i appen."
                    ),
                    HelpItem(
                        title: "Slette alle poster",
                        systemImage: "trash",
                        body: "I Innstillinger kan du slette alle poster. Dette krever bekreftelse. Bruk dette bare når du er sikker på at backup er tatt eller dataene ikke skal beholdes."
                    )
                ]
            )
        ]
    )

    static let english = HelpArticle(
        navigationTitle: "User Guide",
        title: "SaldoPilot User Guide",
        introduction: "SaldoPilot helps you plan income and expenses, follow due dates, register paid bills and received salary, and automatically create the next transaction when something repeats.",
        sections: [
            HelpSection(
                title: "Getting started",
                items: [
                    HelpItem(title: "The basic idea", systemImage: "lightbulb", body: "Add regular income and expenses as transactions. A transaction usually starts as pending. When a bill is paid or salary is received, open the transaction and register the date. The status changes to paid or received."),
                    HelpItem(title: "Overview", systemImage: "gauge.with.dots.needle.33percent", body: "Overview shows balance, income, expenses, overdue transactions, next due date, and pending income for the selected period. Tap overdue, next due, or pending income to open Transactions with the matching filter."),
                    HelpItem(title: "Period", systemImage: "calendar", body: "The from and to dates control which transactions are included in totals and statistics. You can choose the default period in Settings.")
                ]
            ),
            HelpSection(
                title: "Creating transactions",
                items: [
                    HelpItem(title: "Add a bill or expense", systemImage: "minus.circle", body: "Go to Transactions and tap the plus button at the top. Choose Expense, then enter title, amount, category, and due date. Select recurrence if the bill repeats, for example monthly."),
                    HelpItem(title: "Add salary or income", systemImage: "plus.circle", body: "Go to Transactions and tap the plus button at the top. Choose Income, then enter amount, category, and the date you expect to receive the money. For salary, use monthly recurrence if it repeats."),
                    HelpItem(title: "Categories", systemImage: "tag", body: "Categories make statistics and search easier. Choose the category that best fits the transaction, such as Salary, Rent, Food, Gifts, Deduction, or Gambling."),
                    HelpItem(title: "Notes", systemImage: "note.text", body: "Use notes for practical details such as invoice references, account numbers, agreement details, or anything else you want to remember.")
                ]
            ),
            HelpSection(
                title: "Approving payments",
                items: [
                    HelpItem(title: "Register a paid bill", systemImage: "checkmark.circle", body: "When a bill has been paid in your bank, open the transaction from Transactions. Register the paid date and save. The transaction changes to Paid, and the paid date is used by filters, overview, and statistics."),
                    HelpItem(title: "Register received salary or income", systemImage: "banknote", body: "When salary, pension, or other income reaches your account, open the income transaction. Register the received date and save. The transaction changes to Received."),
                    HelpItem(title: "Recurring transactions", systemImage: "repeat", body: "If a transaction has recurrence, the next transaction is created automatically when you mark it as Paid or Received. The new due date is based on the selected interval."),
                    HelpItem(title: "Settled transactions", systemImage: "tray.full", body: "Paid and received transactions can be hidden from the normal list with Show settled transactions in Settings. They can still be shown with the Paid/Received filter.")
                ]
            ),
            HelpSection(
                title: "Transactions list",
                items: [
                    HelpItem(title: "Find the right transaction", systemImage: "line.3.horizontal.decrease.circle", body: "Use the quick filters at the top for all, overdue, next due, upcoming, paid, or receivable. The filter button gives more choices such as period, date type, status, type, category, and amount."),
                    HelpItem(title: "Sorting", systemImage: "arrow.up.arrow.down", body: "In the filter view, sort by due date, paid date, amount, title, category, or status. This is useful when paying several bills on the same day."),
                    HelpItem(title: "Edit, duplicate, and delete", systemImage: "slider.horizontal.3", body: "Swipe a transaction for actions. Edit changes details, Duplicate is useful for similar transactions, and Delete requires confirmation."),
                    HelpItem(title: "Available amount", systemImage: "creditcard", body: "At the top of Transactions, the capsule shows available amount. Green means received income is greater than paid expenses. Red means negative.")
                ]
            ),
            HelpSection(
                title: "Overview and statistics",
                items: [
                    HelpItem(title: "Overview", systemImage: "chart.pie", body: "The front page is for quick control: what has arrived, what has been paid, what is due soon, and what is missing. Use it before paying bills."),
                    HelpItem(title: "Statistics", systemImage: "chart.bar.xaxis", body: "Statistics shows expenses by category and transaction count. This helps you see where money goes in the selected period."),
                    HelpItem(title: "AI summary", systemImage: "sparkles", body: "AI summary can explain the numbers in simple text. External AI can be enabled or disabled in Settings.")
                ]
            ),
            HelpSection(
                title: "Notifications",
                items: [
                    HelpItem(title: "Enable notifications", systemImage: "bell", body: "Go to Settings > Notifications and enable due today, due tomorrow, due in advance, or pending income. iOS must also allow notifications for SaldoPilot."),
                    HelpItem(title: "Timing", systemImage: "clock", body: "Normal due reminders arrive at 09:00. Overdue expenses and pending income are reminded at 18:00. If testing due today after 09:00, the app may schedule a near test reminder about one minute ahead.")
                ]
            ),
            HelpSection(
                title: "Settings and safety",
                items: [
                    HelpItem(title: "Language and appearance", systemImage: "globe", body: "In Settings, choose Norwegian, English, Thai, or system language. You can also choose light, dark, or system appearance."),
                    HelpItem(title: "Backup and export", systemImage: "externaldrive", body: "Use Backup and export to save data as JSON or CSV. JSON is best for a full backup. CSV is useful for Numbers or Excel."),
                    HelpItem(title: "Import", systemImage: "square.and.arrow.down", body: "Use Import data to restore an earlier export. Always take a backup before importing, especially if you already have many transactions."),
                    HelpItem(title: "Delete all transactions", systemImage: "trash", body: "Settings lets you delete all transactions. This requires confirmation. Use it only when you are sure you have a backup or no longer need the data.")
                ]
            )
        ]
    )

    static let thai = HelpArticle(
        navigationTitle: "คู่มือการใช้",
        title: "คู่มือการใช้ SaldoPilot",
        introduction: "SaldoPilot ช่วยวางแผนรายรับ รายจ่าย วันครบกำหนด บันทึกการชำระเงินหรือรับเงินเดือน และสร้างรายการถัดไปให้อัตโนมัติเมื่อรายการเกิดซ้ำ",
        sections: [
            HelpSection(
                title: "เริ่มต้นใช้งาน",
                items: [
                    HelpItem(title: "แนวคิดหลัก", systemImage: "lightbulb", body: "เพิ่มรายรับและรายจ่ายเป็นรายการ รายการจะเริ่มจากสถานะรอดำเนินการ เมื่อจ่ายบิลหรือได้รับเงินเดือนแล้ว ให้เปิดรายการและบันทึกวันที่ สถานะจะเปลี่ยนเป็นจ่ายแล้วหรือได้รับแล้ว"),
                    HelpItem(title: "ภาพรวม", systemImage: "gauge.with.dots.needle.33percent", body: "หน้าภาพรวมแสดงยอดคงเหลือ รายรับ รายจ่าย รายการค้างชำระ วันครบกำหนดถัดไป และรายรับที่รอรับในช่วงเวลาที่เลือก แตะรายการเหล่านี้เพื่อเปิดหน้ารายการพร้อมตัวกรองที่เกี่ยวข้อง"),
                    HelpItem(title: "ช่วงเวลา", systemImage: "calendar", body: "วันที่เริ่มต้นและสิ้นสุดกำหนดว่ารายการใดถูกนำไปคำนวณในยอดรวมและสถิติ สามารถตั้งค่าช่วงเวลาเริ่มต้นได้ในหน้าการตั้งค่า")
                ]
            ),
            HelpSection(
                title: "สร้างรายการ",
                items: [
                    HelpItem(title: "เพิ่มบิลหรือรายจ่าย", systemImage: "minus.circle", body: "ไปที่รายการ แล้วแตะปุ่มบวกด้านบน เลือกประเภทรายจ่าย ใส่ชื่อ จำนวนเงิน หมวดหมู่ และวันครบกำหนด เลือกการเกิดซ้ำหากบิลมาประจำ เช่น รายเดือน"),
                    HelpItem(title: "เพิ่มเงินเดือนหรือรายรับ", systemImage: "plus.circle", body: "ไปที่รายการ แล้วแตะปุ่มบวกด้านบน เลือกประเภทรายรับ ใส่จำนวนเงิน หมวดหมู่ และวันที่คาดว่าจะได้รับเงิน สำหรับเงินเดือนให้เลือกการเกิดซ้ำรายเดือนหากได้รับประจำ"),
                    HelpItem(title: "หมวดหมู่", systemImage: "tag", body: "หมวดหมู่ช่วยให้ดูสถิติและค้นหารายการง่ายขึ้น เลือกหมวดหมู่ที่เหมาะสม เช่น เงินเดือน ค่าเช่า อาหาร ของขวัญ รายการหัก หรือการพนัน"),
                    HelpItem(title: "บันทึกเพิ่มเติม", systemImage: "note.text", body: "ใช้ช่องบันทึกสำหรับรายละเอียด เช่น เลขอ้างอิงใบแจ้งหนี้ เลขบัญชี ข้อมูลสัญญา หรือสิ่งที่ต้องการจำ")
                ]
            ),
            HelpSection(
                title: "ยืนยันการชำระและรับเงิน",
                items: [
                    HelpItem(title: "บันทึกบิลที่จ่ายแล้ว", systemImage: "checkmark.circle", body: "เมื่อจ่ายบิลในธนาคารแล้ว ให้เปิดรายการจากหน้ารายการ บันทึกวันที่จ่ายและบันทึก รายการจะเปลี่ยนเป็นจ่ายแล้ว และวันที่จ่ายจะถูกใช้ในตัวกรอง ภาพรวม และสถิติ"),
                    HelpItem(title: "บันทึกเงินเดือนหรือรายรับที่ได้รับแล้ว", systemImage: "banknote", body: "เมื่อเงินเดือน เงินบำนาญ หรือรายรับอื่นเข้าบัญชีแล้ว ให้เปิดรายการรายรับ บันทึกวันที่ได้รับและบันทึก รายการจะเปลี่ยนเป็นได้รับแล้ว"),
                    HelpItem(title: "รายการที่เกิดซ้ำ", systemImage: "repeat", body: "ถ้ารายการมีการเกิดซ้ำ รายการถัดไปจะถูกสร้างให้อัตโนมัติเมื่อทำเครื่องหมายว่าจ่ายแล้วหรือได้รับแล้ว วันที่ครบกำหนดใหม่จะอิงจากช่วงเวลาที่เลือก"),
                    HelpItem(title: "รายการที่เสร็จแล้ว", systemImage: "tray.full", body: "รายการที่จ่ายแล้วหรือได้รับแล้วสามารถซ่อนจากรายการปกติได้ด้วยตัวเลือกแสดงรายการที่เสร็จแล้วในการตั้งค่า และยังสามารถดูได้ด้วยตัวกรองจ่ายแล้ว/ได้รับแล้ว")
                ]
            ),
            HelpSection(
                title: "หน้ารายการ",
                items: [
                    HelpItem(title: "ค้นหารายการ", systemImage: "line.3.horizontal.decrease.circle", body: "ใช้ตัวกรองด่วนด้านบนเพื่อดูทั้งหมด ค้างชำระ ครบกำหนดถัดไป รายการที่จะมาถึง จ่ายแล้ว หรือรอรับเงิน ปุ่มตัวกรองมีตัวเลือกเพิ่มเติม เช่น ช่วงเวลา ประเภทวันที่ สถานะ ประเภท หมวดหมู่ และจำนวนเงิน"),
                    HelpItem(title: "การเรียงลำดับ", systemImage: "arrow.up.arrow.down", body: "ในหน้าตัวกรอง สามารถเรียงตามวันครบกำหนด วันที่จ่าย จำนวนเงิน ชื่อ หมวดหมู่ หรือสถานะ มีประโยชน์เมื่อจ่ายหลายบิลในวันเดียวกัน"),
                    HelpItem(title: "แก้ไข ทำซ้ำ และลบ", systemImage: "slider.horizontal.3", body: "ปัดรายการเพื่อดูการทำงาน แก้ไขใช้เปลี่ยนรายละเอียด ทำซ้ำใช้กับรายการที่คล้ายกัน และการลบต้องยืนยันก่อน"),
                    HelpItem(title: "ยอดที่พร้อมใช้", systemImage: "creditcard", body: "ด้านบนของหน้ารายการจะแสดงยอดที่พร้อมใช้ในรูปแบบแคปซูล สีเขียวหมายถึงรายรับที่ได้รับมากกว่ารายจ่ายที่จ่ายแล้ว สีแดงหมายถึงติดลบ")
                ]
            ),
            HelpSection(
                title: "ภาพรวมและสถิติ",
                items: [
                    HelpItem(title: "ภาพรวม", systemImage: "chart.pie", body: "หน้าแรกใช้ตรวจสอบอย่างรวดเร็วว่าอะไรเข้ามาแล้ว อะไรจ่ายแล้ว อะไรใกล้ครบกำหนด และอะไรยังขาดอยู่ ใช้ก่อนจ่ายบิลได้ดี"),
                    HelpItem(title: "สถิติ", systemImage: "chart.bar.xaxis", body: "สถิติแสดงรายจ่ายตามหมวดหมู่และจำนวนรายการ ช่วยให้เห็นว่าเงินถูกใช้ไปที่ไหนในช่วงเวลาที่เลือก"),
                    HelpItem(title: "สรุปด้วย AI", systemImage: "sparkles", body: "สรุปด้วย AI สามารถอธิบายตัวเลขเป็นข้อความง่าย ๆ สามารถเปิดหรือปิดการใช้ AI ภายนอกได้ในการตั้งค่า")
                ]
            ),
            HelpSection(
                title: "การแจ้งเตือน",
                items: [
                    HelpItem(title: "เปิดการแจ้งเตือน", systemImage: "bell", body: "ไปที่การตั้งค่า > การแจ้งเตือน แล้วเปิดรายการที่ต้องการ เช่น ครบกำหนดวันนี้ พรุ่งนี้ แจ้งล่วงหน้า หรือรายรับที่รอรับ iOS ต้องอนุญาตการแจ้งเตือนให้ SaldoPilot ด้วย"),
                    HelpItem(title: "เวลาแจ้งเตือน", systemImage: "clock", body: "การแจ้งเตือนครบกำหนดปกติมาเวลา 09:00 รายจ่ายค้างชำระและรายรับที่รอรับเตือนเวลา 18:00 หากทดสอบครบกำหนดวันนี้หลัง 09:00 แอปอาจตั้งการแจ้งเตือนทดสอบประมาณหนึ่งนาทีถัดไป")
                ]
            ),
            HelpSection(
                title: "การตั้งค่าและความปลอดภัย",
                items: [
                    HelpItem(title: "ภาษาและรูปลักษณ์", systemImage: "globe", body: "ในการตั้งค่า เลือกภาษาอังกฤษ นอร์เวย์ ไทย หรือภาษาของระบบได้ และเลือกโหมดสว่าง มืด หรือให้ระบบกำหนด"),
                    HelpItem(title: "สำรองและส่งออก", systemImage: "externaldrive", body: "ใช้สำรองและส่งออกเพื่อบันทึกข้อมูลเป็น JSON หรือ CSV ไฟล์ JSON เหมาะกับการสำรองเต็มรูปแบบ CSV เหมาะสำหรับเปิดใน Numbers หรือ Excel"),
                    HelpItem(title: "นำเข้า", systemImage: "square.and.arrow.down", body: "ใช้นำเข้าข้อมูลเพื่อกู้คืนไฟล์ที่เคยส่งออก ควรสำรองข้อมูลก่อนนำเข้าเสมอ โดยเฉพาะเมื่อมีรายการอยู่แล้วจำนวนมาก"),
                    HelpItem(title: "ลบรายการทั้งหมด", systemImage: "trash", body: "ในการตั้งค่าสามารถลบรายการทั้งหมดได้ การลบต้องยืนยันก่อน ใช้เฉพาะเมื่อแน่ใจว่ามีสำรองข้อมูลแล้วหรือไม่ต้องการเก็บข้อมูลอีก")
                ]
            )
        ]
    )
}
