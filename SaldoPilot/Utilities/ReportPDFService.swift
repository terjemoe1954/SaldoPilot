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
    let categoryName: String?
    let notes: String
    let isIncludedInOrdinaryCashFlow: Bool

    init(transaction: Transaction, transactionDate: Date, categoryName: String? = nil) {
        id = transaction.id
        title = transaction.title
        amount = transaction.amount
        type = transaction.type
        self.transactionDate = transactionDate
        status = transaction.effectiveStatus
        category = transaction.category
        self.categoryName = categoryName
        notes = transaction.notes
        isIncludedInOrdinaryCashFlow = transaction.isIncludedInOrdinaryCashFlow
    }
}

@MainActor
enum ReportPDFService {
    static func makeOverdueChecklist(
        transactions: [ReportTransaction],
        locale: Locale
    ) throws -> URL {
        let strings = ReportStrings(locale: locale)
        let pageBounds = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = 32
        let contentWidth = pageBounds.width - margin * 2
        let rowHeight: CGFloat = 30
        let sortedTransactions = transactions.sorted { $0.transactionDate < $1.transactionDate }
        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.setLocalizedDateFormatFromTemplate("d MMM yyyy")
        let currencyFormatter = NumberFormatter()
        currencyFormatter.locale = locale
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = "NOK"
        let totalAmount = sortedTransactions.reduce(Decimal.zero) { $0 + $1.amount }
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)

        let data = renderer.pdfData { context in
            var index = 0
            var pageNumber = 0

            repeat {
                context.beginPage()
                context.cgContext.setFillColor(UIColor.white.cgColor)
                context.cgContext.fill(pageBounds)
                pageNumber += 1

                draw(strings.overdueChecklist, rect: CGRect(x: margin, y: margin, width: contentWidth, height: 28), font: .boldSystemFont(ofSize: 20))
                draw("\(strings.generated): \(Date.now.formatted(date: .abbreviated, time: .shortened))", rect: CGRect(x: margin, y: margin + 31, width: contentWidth, height: 16), font: .systemFont(ofSize: 9), color: .darkGray)
                draw("\(strings.count): \(sortedTransactions.count)    \(strings.total): \(currency(totalAmount, formatter: currencyFormatter))", rect: CGRect(x: margin, y: margin + 47, width: contentWidth, height: 16), font: .systemFont(ofSize: 9), color: .darkGray)
                draw("\(strings.page) \(pageNumber)", rect: CGRect(x: margin, y: margin, width: contentWidth, height: 16), font: .systemFont(ofSize: 9), color: .darkGray, alignment: .right)

                var y = margin + 73
                context.cgContext.setFillColor(UIColor(white: 0.86, alpha: 1).cgColor)
                context.cgContext.fill(CGRect(x: margin, y: y, width: contentWidth, height: 24))
                draw(strings.paid, rect: CGRect(x: margin + 4, y: y + 6, width: 34, height: 14), font: .boldSystemFont(ofSize: 8))
                draw(strings.dueDate, rect: CGRect(x: margin + 42, y: y + 6, width: 82, height: 14), font: .boldSystemFont(ofSize: 8))
                draw(strings.title, rect: CGRect(x: margin + 126, y: y + 6, width: 205, height: 14), font: .boldSystemFont(ofSize: 8))
                draw(strings.category, rect: CGRect(x: margin + 334, y: y + 6, width: 105, height: 14), font: .boldSystemFont(ofSize: 8))
                draw(strings.amount, rect: CGRect(x: margin + 442, y: y + 6, width: contentWidth - 446, height: 14), font: .boldSystemFont(ofSize: 8), alignment: .right)
                y += 24

                while index < sortedTransactions.count, y + rowHeight < pageBounds.height - 44 {
                    let transaction = sortedTransactions[index]
                    context.cgContext.setStrokeColor(UIColor.black.cgColor)
                    context.cgContext.setLineWidth(1)
                    context.cgContext.stroke(CGRect(x: margin + 10, y: y + 9, width: 12, height: 12))
                    draw(dateFormatter.string(from: transaction.transactionDate), rect: CGRect(x: margin + 42, y: y + 8, width: 82, height: 14), font: .systemFont(ofSize: 8))
                    draw(transaction.title, rect: CGRect(x: margin + 126, y: y + 8, width: 205, height: 14), font: .systemFont(ofSize: 8))
                    draw(transaction.categoryName ?? transaction.category.localizedTitle(locale: locale), rect: CGRect(x: margin + 334, y: y + 8, width: 105, height: 14), font: .systemFont(ofSize: 8))
                    draw(currency(transaction.amount, formatter: currencyFormatter), rect: CGRect(x: margin + 442, y: y + 8, width: contentWidth - 446, height: 14), font: .systemFont(ofSize: 8), alignment: .right)
                    context.cgContext.setStrokeColor(UIColor.separator.cgColor)
                    context.cgContext.setLineWidth(0.4)
                    context.cgContext.move(to: CGPoint(x: margin, y: y + rowHeight))
                    context.cgContext.addLine(to: CGPoint(x: margin + contentWidth, y: y + rowHeight))
                    context.cgContext.strokePath()
                    y += rowHeight
                    index += 1
                }

                drawFooter(strings: strings, pageNumber: pageNumber, pageBounds: pageBounds, margin: margin)
            } while index < sortedTransactions.count
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("SaldoPilot-Overdue-Checklist-\(fileDay(from: .now)).pdf")
        try data.write(to: url, options: .atomic)
        return url
    }

    static func makeMonthlyReport(
        transactions: [ReportTransaction],
        monthStart: Date,
        locale: Locale,
        dateType: AppDefaultDateType,
        reportTitle: String,
        selectionDescription: String
    ) throws -> URL {
        let strings = ReportStrings(locale: locale)
        let pageBounds = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = 28
        let contentWidth = pageBounds.width - margin * 2
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        let sortedTransactions = transactions.sorted { $0.transactionDate < $1.transactionDate }
        let tableRows = sortedTransactions.flatMap { tableRows(for: $0, strings: strings) }
        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.setLocalizedDateFormatFromTemplate("d MMM yyyy")
        let monthFormatter = DateFormatter()
        monthFormatter.locale = locale
        monthFormatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        let currencyFormatter = NumberFormatter()
        currencyFormatter.locale = locale
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = "NOK"

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
                    reportTitle: reportTitle,
                    selectionDescription: selectionDescription,
                    monthTitle: monthFormatter.string(from: monthStart),
                    count: sortedTransactions.count,
                    pageNumber: pageNumber,
                    dateType: dateType,
                    x: margin,
                    y: y,
                    width: contentWidth
                )
                y = drawTableHeader(context: context.cgContext, strings: strings, x: margin, y: y, width: contentWidth)

                while rowIndex < tableRows.count {
                    let row = tableRows[rowIndex]
                    let rowHeight = tableRowHeight(for: row)
                    guard y + rowHeight < pageBounds.height - 52 else { break }
                    drawTransactionRow(
                        context: context.cgContext,
                        row: row,
                        rowHeight: rowHeight,
                        strings: strings,
                        dateFormatter: dateFormatter,
                        currencyFormatter: currencyFormatter,
                        locale: locale,
                        x: margin,
                        y: y,
                        width: contentWidth
                    )
                    y += rowHeight
                    rowIndex += 1
                }

                if rowIndex == tableRows.count {
                    let summaryHeight: CGFloat = dateType == .paidDate ? 70 : 106
                    if y + summaryHeight > pageBounds.height - 52 {
                        context.beginPage()
                        context.cgContext.setFillColor(UIColor.white.cgColor)
                        context.cgContext.fill(pageBounds)
                        pageNumber += 1
                        y = drawPageHeader(
                            context: context.cgContext,
                            strings: strings,
                            reportTitle: reportTitle,
                            selectionDescription: selectionDescription,
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
            } while rowIndex < tableRows.count
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
        reportTitle: String,
        selectionDescription: String,
        monthTitle: String,
        count: Int,
        pageNumber: Int,
        dateType: AppDefaultDateType,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat
    ) -> CGFloat {
        draw(reportTitle, rect: CGRect(x: x, y: y, width: width, height: 28), font: .boldSystemFont(ofSize: 20))
        let generated = strings.generated + ": " + Date.now.formatted(date: .abbreviated, time: .shortened)
        draw(generated, rect: CGRect(x: x, y: y + 32, width: width, height: 18), font: .systemFont(ofSize: 9), color: .darkGray)
        draw("\(strings.period): \(monthTitle)    \(strings.count): \(count)    \(strings.sorting): \(strings.sortingTitle(for: dateType))", rect: CGRect(x: x, y: y + 49, width: width, height: 18), font: .systemFont(ofSize: 9), color: .darkGray)
        draw(selectionDescription, rect: CGRect(x: x, y: y + 66, width: width, height: 18), font: .systemFont(ofSize: 9), color: .darkGray)
        draw("\(strings.page) \(pageNumber)", rect: CGRect(x: x, y: y, width: width, height: 18), font: .systemFont(ofSize: 9), color: .darkGray, alignment: .right)
        context.setStrokeColor(UIColor.separator.cgColor)
        context.move(to: CGPoint(x: x, y: y + 89))
        context.addLine(to: CGPoint(x: x + width, y: y + 89))
        context.strokePath()
        return y + 99
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
        row: ReportTableRow,
        rowHeight: CGFloat,
        strings: ReportStrings,
        dateFormatter: DateFormatter,
        currencyFormatter: NumberFormatter,
        locale: Locale,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat
    ) {
        let transaction = row.transaction
        if !row.isContinuation {
            draw(dateFormatter.string(from: transaction.transactionDate), rect: CGRect(x: x + 4, y: y + 5, width: 74, height: 14), font: .systemFont(ofSize: 8))
            draw(currency(transaction.amount, formatter: currencyFormatter), rect: CGRect(x: x + 270, y: y + 5, width: 86, height: 14), font: .systemFont(ofSize: 8), alignment: .right)
            draw(strings.statusTitle(transaction.status), rect: CGRect(x: x + 363, y: y + 5, width: 76, height: 14), font: .systemFont(ofSize: 8))
            draw(transaction.categoryName ?? transaction.category.localizedTitle(locale: locale), rect: CGRect(x: x + 442, y: y + 5, width: width - 446, height: 14), font: .systemFont(ofSize: 8))
        }
        drawWrapped(row.text, rect: CGRect(x: x + 79, y: y + 5, width: 190, height: rowHeight - 10), font: .systemFont(ofSize: 8))
        context.setStrokeColor(UIColor.separator.cgColor)
        context.setLineWidth(0.4)
        context.move(to: CGPoint(x: x, y: y + rowHeight - 0.5))
        context.addLine(to: CGPoint(x: x + width, y: y + rowHeight - 0.5))
        context.strokePath()
    }

    private static func tableRows(for transaction: ReportTransaction, strings: ReportStrings) -> [ReportTableRow] {
        let text = transaction.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? transaction.title
            : "\(transaction.title)\n\(strings.notes): \(transaction.notes)"
        return splitForTable(text).enumerated().map { index, segment in
            ReportTableRow(transaction: transaction, text: segment, isContinuation: index > 0)
        }
    }

    private static func splitForTable(_ text: String) -> [String] {
        let maximumHeight: CGFloat = 180
        let width: CGFloat = 190
        let font = UIFont.systemFont(ofSize: 8)

        func split(_ value: String) -> [String] {
            guard textHeight(value, width: width, font: font) > maximumHeight,
                  value.count > 1 else {
                return [value]
            }

            let middle = value.index(value.startIndex, offsetBy: value.count / 2)
            let prefix = value[..<middle]
            let splitIndex = prefix.lastIndex(where: { $0.isWhitespace }) ?? middle
            let first = String(value[..<splitIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            let secondStart = value[splitIndex...].first?.isWhitespace == true
                ? value.index(after: splitIndex)
                : splitIndex
            let second = String(value[secondStart...]).trimmingCharacters(in: .whitespacesAndNewlines)

            guard !first.isEmpty, !second.isEmpty else {
                return [value]
            }
            return split(first) + split(second)
        }

        return split(text)
    }

    private static func tableRowHeight(for row: ReportTableRow) -> CGFloat {
        max(23, ceil(textHeight(row.text, width: 190, font: .systemFont(ofSize: 8))) + 10)
    }

    private static func textHeight(_ text: String, width: CGFloat, font: UIFont) -> CGFloat {
        (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).height
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
        let received = total(transactions) {
            $0.isIncludedInOrdinaryCashFlow && $0.type == .income && $0.status == .received
        }
        let paid = total(transactions) {
            $0.isIncludedInOrdinaryCashFlow && $0.type == .expense && $0.status == .paid
        }
        let rows: [(String, Decimal)]
        if dateType == .paidDate {
            rows = [
                (strings.incomeReceived, received),
                (strings.expensesPaid, paid)
            ]
        } else {
            let pendingIncome = total(transactions) {
                $0.isIncludedInOrdinaryCashFlow
                    && $0.type == .income
                    && ($0.status == .pending || $0.status == .overdue)
            }
            let unpaidExpenses = total(transactions) {
                $0.isIncludedInOrdinaryCashFlow
                    && $0.type == .expense
                    && ($0.status == .pending || $0.status == .overdue)
            }
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

    private static func drawWrapped(_ text: String, rect: CGRect, font: UIFont) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        (text as NSString).draw(
            in: rect,
            withAttributes: [
                .font: font,
                .foregroundColor: UIColor.black,
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

    private static func fileDay(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private struct ReportTableRow {
    let transaction: ReportTransaction
    let text: String
    let isContinuation: Bool
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
    var notes: String { languageCode == "nb" ? "Notat" : languageCode == "th" ? "บันทึก" : "Note" }
    var summary: String { languageCode == "nb" ? "Oppsummering" : languageCode == "th" ? "สรุป" : "Summary" }
    var incomeReceived: String { languageCode == "nb" ? "Inntekt mottatt" : languageCode == "th" ? "รายรับที่ได้รับ" : "Income received" }
    var expensesPaid: String { languageCode == "nb" ? "Utgift betalt" : languageCode == "th" ? "รายจ่ายที่จ่ายแล้ว" : "Expenses paid" }
    var incomePending: String { languageCode == "nb" ? "Inntekt venter" : languageCode == "th" ? "รายรับที่รอรับ" : "Income pending" }
    var expensesUnpaid: String { languageCode == "nb" ? "Utgift ubetalt" : languageCode == "th" ? "รายจ่ายที่ยังไม่จ่าย" : "Expenses unpaid" }
    var page: String { languageCode == "nb" ? "Side" : languageCode == "th" ? "หน้า" : "Page" }
    var overdueChecklist: String { languageCode == "nb" ? "Forfalte poster – avkrysningsliste" : languageCode == "th" ? "รายการเกินกำหนด – รายการตรวจสอบ" : "Overdue transactions – checklist" }
    var paid: String { languageCode == "nb" ? "Betalt" : languageCode == "th" ? "จ่ายแล้ว" : "Paid" }
    var dueDate: String { languageCode == "nb" ? "Forfallsdato" : languageCode == "th" ? "วันครบกำหนด" : "Due date" }
    var total: String { languageCode == "nb" ? "Totalt" : languageCode == "th" ? "รวม" : "Total" }

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
