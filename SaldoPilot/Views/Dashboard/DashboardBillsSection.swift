import SwiftData
import SwiftUI

@MainActor
enum DashboardBillsSelection {
    struct Result {
        let overdue: [Transaction]
        let upcoming: [Transaction]
        var total: Decimal { (overdue + upcoming).reduce(.zero) { $0 + $1.amount } }
    }
    static func calculate(_ transactions: [Transaction], now: Date = .now, calendar: Calendar = .current) -> Result {
        let today = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        let unpaid = UnpaidBillsSelection.bills(from: transactions, overdueOnly: false, now: now, calendar: calendar)
        return Result(overdue: unpaid.filter { $0.dueDate < today },
                      upcoming: unpaid.filter { $0.dueDate >= today && $0.dueDate < end })
    }
}

struct DashboardBillsSection: View {
    let transactions: [Transaction]
    @Environment(\.locale) private var locale
    @State private var payment: Transaction?
    // Refresh due labels across midnight while the app remains open.
    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            content(DashboardBillsSelection.calculate(transactions, now: timeline.date))
        }
        .sheet(item: $payment) { TransactionPaymentSheet(transaction: $0) }
    }
    private func content(_ selection: DashboardBillsSelection.Result) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Bills", systemImage: "checklist").font(.headline)
                Spacer()
                NavigationLink { UnpaidBillsView(scope: .allUnpaid) } label: { Text("View all") }.font(.subheadline)
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { statusLabels(selection) }
                VStack(alignment: .leading, spacing: 10) { statusLabels(selection) }
            }
            if selection.overdue.isEmpty && selection.upcoming.isEmpty {
                Label("No unpaid bills due in the next 7 days.", systemImage: "checkmark.circle")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            if !selection.overdue.isEmpty {
                billGroup(selection.overdue, title: "Overdue bills", overdue: true)
            }
            if !selection.upcoming.isEmpty {
                billGroup(selection.upcoming, title: "Upcoming bills", overdue: false)
            }
            if !selection.overdue.isEmpty || !selection.upcoming.isEmpty {
                Divider()
                LabeledContent("Unpaid in this overview", value: selection.total.formattedCurrency)
                    .font(.subheadline.weight(.medium))
            }
            Text("All overdue bills and bills due in the next 7 days, independent of the selected period.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }
    @ViewBuilder private func statusLabels(_ result: DashboardBillsSelection.Result) -> some View {
        Label {
            if result.overdue.isEmpty { Text("No overdue bills") }
            else { Text("Overdue: \(result.overdue.count)") }
        } icon: {
            Image(systemName: result.overdue.isEmpty ? "checkmark.circle" : "exclamationmark.triangle")
        }
            .foregroundStyle(result.overdue.isEmpty ? Color.green : Color.red)
            .font(.caption.weight(.medium)).padding(8)
            .background((result.overdue.isEmpty ? Color.green : Color.red).opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        Text("Next 7 days: \(result.upcoming.count)").font(.caption.weight(.medium)).padding(8)
            .foregroundStyle(.blue).background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
    private func billGroup(_ bills: [Transaction], title: LocalizedStringKey, overdue: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            ForEach(Array(bills.prefix(4))) { bill in
                HStack(spacing: 10) {
                    Button { payment = bill } label: {
                        Image(systemName: "circle").font(.title2).frame(width: 44, height: 44)
                    }.buttonStyle(.borderless).accessibilityLabel(Text("Mark paid: \(bill.title)"))
                    NavigationLink { TransactionDetailView(transaction: bill) } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(bill.title).font(.subheadline.weight(.medium)).foregroundStyle(.primary)
                            Text(bill.dueDate, format: .dateTime.day().month(.abbreviated).year().locale(locale))
                                .font(.caption).foregroundStyle(overdue ? Color.red : Color.secondary)
                            Text(bill.amount.formattedCurrency).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                if bill.id != bills.prefix(4).last?.id { Divider() }
            }
            if bills.count > 4 {
                NavigationLink { UnpaidBillsView(scope: overdue ? .overdueOnly : .allUnpaid) } label: {
                    Text("View all \(bills.count) bills")
                }.font(.caption)
            }
        }
    }
}
