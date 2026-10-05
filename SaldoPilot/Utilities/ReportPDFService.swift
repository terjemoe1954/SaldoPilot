import Foundation
import UIKit

struct ReportTransaction {
    let id: UUID
    let title: String
    let amount: Decimal
    let type: TransactionType
    let transactionDate: Date
    let status: TransactionStatus
    let category: CategoryKind

    init(transaction: Transaction, transactionDate: Date) {
        id = transaction.id
        title = transaction.title
        amount = transaction.amount
        type = transaction.type
        self.transactionDate = transactionDate
        status = transaction.effectiveStatus
        category = transaction.category
    }
}

@MainActor
enum ReportPDFService {
    static func makeMonthlyReport(
        transactions: [ReportTransaction],
        monthStart: Date,
        locale: Locale,
        dateType: AppDefaultDateType
    ) throws -> URL {
        let strings = ReportStrings(locale: locale)
        let pageBounds = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = 28
        let contentWidth = pageBounds.width - margin * 2
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        let sortedTransactions = transactions.sorted { $0.transactionDate < $1.transactionDate }
        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.setLocalizedDateFormatFromTemplate("d MMM yyyy")
        let monthFormatter = DateFormatter()
        monthFormatter.locale = locale
        monthFormatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        let currencyFormatter = NumberFormatter()
        currencyFormatter.locale = locale
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = locale.currency?.identifier ?? "NOK"

        let data = renderer.pdfData { context in
            var rowIndex = 0
            var pageNumber = 0

            repeat {
                context.beginPage()
                context.cgContext.setFillColor(UIColor.white.cgColor)
                context.cgContext.fill(pageBounds)
                pageNumber += 1
                var y = margin
                y = drawPageHeader(
                    context: context.cgContext,
                    strings: strings,
                    monthTitle: monthFormatter.string(from: monthStart),
                    count: sortedTransactions.count,
                    pageNumber: pageNumber,
                    dateType: dateType,
                    x: margin,
                    y: y,
                    width: contentWidth
                )
                y = drawTableHeader(context: context.cgContext, strings: strings, x: margin, y: y, width: contentWidth)

                while rowIndex < sortedTransactions.count && y + 23 < pageBounds.height - 82 {
                    let transaction = sortedTransactions[rowIndex]
                    drawTransactionRow(
                        context: context.cgContext,
                        transaction: transaction,
                        strings: strings,
                        dateFormatter: dateFormatter,
                        currencyFormatter: currencyFormatter,
                        locale: locale,
                        x: margin,
                        y: y,
                        width: contentWidth
                    )
                    y += 23
                    rowIndex += 1
                }

                if rowIndex == sortedTransactions.count {
                    let summaryHeight: CGFloat = dateType == .paidDate ? 70 : 106
                    if y + summaryHeight > pageBounds.height - 52 {
                        context.beginPage()
                        context.cgContext.setFillColor(UIColor.white.cgColor)
                        context.cgContext.fill(pageBounds)
                        pageNumber += 1
                        y = drawPageHeader(
                            context: context.cgContext,
                            strings: strings,
                            monthTitle: monthFormatter.string(from: monthStart),
                            count: sortedTransactions.count,
                            pageNumber: pageNumber,
                            dateType: dateType,
                            x: margin,
                            y: margin,
                            width: contentWidth
                        )
                    }
                    drawSummary(
                        transactions: sortedTransactions,
                        strings: strings,
                        dateType: dateType,
                        currencyFormatter: currencyFormatter,
                        x: margin,
                        y: y + 14,
                        width: contentWidth
                    )
                }

                drawFooter(strings: strings, pageNumber: pageNumber, pageBounds: pageBounds, margin: margin)
            } while rowIndex < sortedTransactions.count
        }

        let fileName = "SaldoPilot-Report-\(fileMonth(from: monthStart)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return url
    }

    static func printReport(at url: URL, jobName: String) {
        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)
        info.jobName = jobName
        info.outputType = .general
        controller.printInfo = info
        controller.printingItem = url
        controller.present(animated: true)
    }

    private static func drawPageHeader(
        context: CGContext,
        strings: ReportStrings,
        monthTitle: String,
        count: Int,
        pageNumber: Int,
        dateType: AppDefaultDateType,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat
    ) -> CGFloat {
        draw(strings.reportTitle, rect: CGRect(x: x, y: y, width: width, height: 28), font: .boldSystemFont(ofSize: 20))
        let generated = strings.generated + ": " + Date.now.formatted(date: .abbreviated, time: .shortened)
        draw(generated, rect: CGRect(x: x, y: y + 32, width: width, height: 18), font: .systemFont(ofSize: 9), color: .darkGray)
        draw("\(strings.period): \(monthTitle)    \(strings.count): \(count)    \(strings.sorting): \(strings.sortingTitle(for: dateType))", rect: CGRect(x: x, y: y + 49, width: width, height: 18), font: .systemFont(ofSize: 9), color: .darkGray)
        draw("\(strings.page) \(pageNumber)", rect: CGRect(x: x, y: y, width: width, height: 18), font: .systemFont(ofSize: 9), color: .darkGray, alignment: .right)
        context.setStrokeColor(UIColor.separator.cgColor)
        context.move(to: CGPoint(x: x, y: y + 72))
        context.addLine(to: CGPoint(x: x + width, y: y + 72))
        context.strokePath()
        return y + 82
    }

    private static func drawTableHeader(context: CGContext, strings: ReportStrings, x: CGFloat, y: CGFloat, width: CGFloat) -> CGFloat {
        context.setFillColor(UIColor(white: 0.82, alpha: 1).cgColor)
        context.fill(CGRect(x: x, y: y, width: width, height: 22))
        draw(strings.date, rect: CGRect(x: x + 4, y: y + 5, width: 74, height: 14), font: .boldSystemFont(ofSize: 8))
        draw(strings.title, rect: CGRect(x: x + 79, y: y + 5, width: 190, height: 14), font: .boldSystemFont(ofSize: 8))
        draw(strings.amount, rect: CGRect(x: x + 270, y: y + 5, width: 86, height: 14), font: .boldSystemFont(ofSize: 8), alignment: .right)
        draw(strings.status, rect: CGRect(x: x + 363, y: y + 5, width: 76, height: 14), font: .boldSystemFont(ofSize: 8))
        draw(strings.category, rect: CGRect(x: x + 442, y: y + 5, width: width - 446, height: 14), font: .boldSystemFont(ofSize: 8))
        return y + 22
    }

    private static func drawTransactionRow(
        context: CGContext,
        transaction: ReportTransaction,
        strings: ReportStrings,
        dateFormatter: DateFormatter,
        currencyFormatter: NumberFormatter,
        locale: Locale,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat
    ) {
        draw(dateFormatter.string(from: transaction.transactionDate), rect: CGRect(x: x + 4, y: y + 5, width: 74, height: 14), font: .systemFont(ofSize: 8))
        draw(transaction.title, rect: CGRect(x: x + 79, y: y + 5, width: 190, height: 14), font: .systemFont(ofSize: 8))
        draw(currency(transaction.amount, formatter: currencyFormatter), rect: CGRect(x: x + 270, y: y + 5, width: 86, height: 14), font: .systemFont(ofSize: 8), alignment: .right)
        draw(strings.statusTitle(transaction.status), rect: CGRect(x: x + 363, y: y + 5, width: 76, height: 14), font: .systemFont(ofSize: 8))
        draw(transaction.category.localizedTitle(locale: locale), rect: CGRect(x: x + 442, y: y + 5, width: width - 446, height: 14), font: .systemFont(ofSize: 8))
        context.setStrokeColor(UIColor.separator.cgColor)
        context.setLineWidth(0.4)
        context.move(to: CGPoint(x: x, y: y + 22.5))
        context.addLine(to: CGPoint(x: x + width, y: y + 22.5))
        context.strokePath()
    }

    private static func drawSummary(
        transactions: [ReportTransaction],
        strings: ReportStrings,
        dateType: AppDefaultDateType,
        currencyFormatter: NumberFormatter,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat
    ) {
        draw(strings.summary, rect: CGRect(x: x, y: y, width: width, height: 22), font: .boldSystemFont(ofSize: 14))
        let received = total(transactions) { $0.type == .income && $0.status == .received }
        let paid = total(transactions) { $0.type == .expense && $0.status == .paid }
        let rows: [(String, Decimal)]
        if dateType == .paidDate {
            rows = [
                (strings.incomeReceived, received),
                (strings.expensesPaid, paid)
            ]
        } else {
            let pendingIncome = total(transactions) { $0.type == .income && ($0.status == .pending || $0.status == .overdue) }
            let unpaidExpenses = total(transactions) { $0.type == .expense && ($0.status == .pending || $0.status == .overdue) }
            rows = [
                (strings.incomeReceived, received),
                (strings.expensesPaid, paid),
                (strings.incomePending, pendingIncome),
                (strings.expensesUnpaid, unpaidExpenses)
            ]
        }
        for (index, row) in rows.enumerated() {
            let rowY = y + 27 + CGFloat(index) * 18
            draw(row.0, rect: CGRect(x: x, y: rowY, width: width * 0.65, height: 16), font: .systemFont(ofSize: 10))
            draw(currency(row.1, formatter: currencyFormatter), rect: CGRect(x: x + width * 0.65, y: rowY, width: width * 0.35, height: 16), font: .boldSystemFont(ofSize: 10), alignment: .right)
        }
    }

    private static func drawFooter(strings: ReportStrings, pageNumber: Int, pageBounds: CGRect, margin: CGFloat) {
        draw("SaldoPilot · \(strings.page) \(pageNumber)", rect: CGRect(x: margin, y: pageBounds.height - 34, width: pageBounds.width - margin * 2, height: 15), font: .systemFont(ofSize: 8), color: .gray, alignment: .center)
    }

    private static func total(_ transactions: [ReportTransaction], where predicate: (ReportTransaction) -> Bool) -> Decimal {
        transactions.filter(predicate).reduce(.zero) { $0 + $1.amount }
    }

    private static func currency(_ value: Decimal, formatter: NumberFormatter) -> String {
        formatter.string(from: NSDecimalNumber(decimal: value)) ?? value.description
    }

    private static func draw(
        _ text: String,
        rect: CGRect,
        font: UIFont,
        color: UIColor = .black,
        alignment: NSTextAlignment = .left
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byTruncatingTail
        (text as NSString).draw(
            in: rect,
            withAttributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraph
            ]
        )
    }

    private static func fileMonth(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
}

private struct ReportStrings {
    let locale: Locale

    private var languageCode: String {
        locale.language.languageCode?.identifier ?? "en"
    }

    var reportTitle: String { languageCode == "nb" ? "SaldoPilot Bilagsrapport" : languageCode == "th" ? "รายงานรายการ SaldoPilot" : "SaldoPilot Transaction Report" }
    var generated: String { languageCode == "nb" ? "Generert" : languageCode == "th" ? "สร้างเมื่อ" : "Generated" }
    var period: String { languageCode == "nb" ? "Periode" : languageCode == "th" ? "ช่วงเวลา" : "Period" }
    var count: String { languageCode == "nb" ? "Antall" : languageCode == "th" ? "จำนวน" : "Count" }
    var sorting: String { languageCode == "nb" ? "Sortert" : languageCode == "th" ? "เรียงตาม" : "Sorted" }
    var dueDateAscending: String { languageCode == "nb" ? "Forfallsdato (stigende)" : languageCode == "th" ? "วันครบกำหนด (จากน้อยไปมาก)" : "Due date (ascending)" }
    var paymentDateAscending: String { languageCode == "nb" ? "Betalingsdato (stigende)" : languageCode == "th" ? "วันที่ชำระเงิน (จากน้อยไปมาก)" : "Payment date (ascending)" }
    var date: String { languageCode == "nb" ? "Dato" : languageCode == "th" ? "วันที่" : "Date" }
    var title: String { languageCode == "nb" ? "Tittel" : languageCode == "th" ? "ชื่อ" : "Title" }
    var amount: String { languageCode == "nb" ? "Beløp" : languageCode == "th" ? "จำนวนเงิน" : "Amount" }
    var status: String { languageCode == "nb" ? "Status" : languageCode == "th" ? "สถานะ" : "Status" }
    var category: String { languageCode == "nb" ? "Kategori" : languageCode == "th" ? "หมวดหมู่" : "Category" }
    var summary: String { languageCode == "nb" ? "Oppsummering" : languageCode == "th" ? "สรุป" : "Summary" }
    var incomeReceived: String { languageCode == "nb" ? "Inntekt mottatt" : languageCode == "th" ? "รายรับที่ได้รับ" : "Income received" }
    var expensesPaid: String { languageCode == "nb" ? "Utgift betalt" : languageCode == "th" ? "รายจ่ายที่จ่ายแล้ว" : "Expenses paid" }
    var incomePending: String { languageCode == "nb" ? "Inntekt venter" : languageCode == "th" ? "รายรับที่รอรับ" : "Income pending" }
    var expensesUnpaid: String { languageCode == "nb" ? "Utgift ubetalt" : languageCode == "th" ? "รายจ่ายที่ยังไม่จ่าย" : "Expenses unpaid" }
    var page: String { languageCode == "nb" ? "Side" : languageCode == "th" ? "หน้า" : "Page" }

    func sortingTitle(for dateType: AppDefaultDateType) -> String {
        dateType == .paidDate ? paymentDateAscending : dueDateAscending
    }

    func statusTitle(_ status: TransactionStatus) -> String {
        switch (languageCode, status) {
        case ("nb", .pending): "Venter"
        case ("nb", .overdue): "Forfalt"
        case ("nb", .paid): "Betalt"
        case ("nb", .received): "Mottatt"
        case ("nb", .cancelled): "Kansellert"
        case ("th", .pending): "รอดำเนินการ"
        case ("th", .overdue): "เกินกำหนด"
        case ("th", .paid): "จ่ายแล้ว"
        case ("th", .received): "ได้รับแล้ว"
        case ("th", .cancelled): "ยกเลิก"
        case (_, .pending): "Pending"
        case (_, .overdue): "Overdue"
        case (_, .paid): "Paid"
        case (_, .received): "Received"
        case (_, .cancelled): "Cancelled"
        }
    }
}
