import Foundation
import Observation

/// Value snapshots intentionally contain no SwiftData objects and never mutate transactions.
enum ForecastChanges {
    struct Line: Codable, Equatable, Identifiable {
        let id: String
        let transactionID: UUID
        let title: String
        let date: Date
        let amount: Decimal
        let income: Bool
        let projected: Bool
        var signedAmount: Decimal { income ? amount : -amount }
    }
    struct Snapshot: Codable, Equatable {
        var version = 1
        let capturedAt: Date
        let startDate: Date
        let salaryID: UUID
        let payday: Date
        let lines: [Line]
        var net: Decimal { lines.reduce(0) { $0 + $1.signedAmount } }
        var isValid: Bool {
            version == 1 && Set(lines.map(\.id)).count == lines.count
                && [capturedAt, startDate, payday].allSatisfy { $0.timeIntervalSinceReferenceDate.isFinite }
                && lines.allSatisfy { !$0.amount.isNaN && $0.amount >= 0 && $0.date.timeIntervalSinceReferenceDate.isFinite }
        }
        init(result: PaydayForecast.Result, capturedAt: Date = .now, calendar: Calendar = .current) {
            self.capturedAt = capturedAt
            startDate = result.startDate
            salaryID = result.salary.id
            payday = result.salary.dueDate
            lines = (result.income + result.expenses).map { entry in
                // A generated occurrence becoming a real series record keeps the same identity.
                let identity = entry.transaction.recurrenceSeriesID.map {
                    $0.uuidString + ":" + String(calendar.startOfDay(for: entry.date).timeIntervalSince1970)
                } ?? entry.id
                return Line(id: identity, transactionID: entry.transaction.id, title: entry.transaction.title,
                            date: entry.date, amount: entry.amount, income: entry.transaction.type == .income, projected: entry.projected)
            }
        }
    }
    enum Reason {
        case included, amountChanged, dateChanged, titleChanged, received, paid, cancelled, archived, noLongerIncluded, occurrenceRegistered, typeChanged
    }
    struct Change: Identifiable {
        let before: Line?
        let after: Line?
        let reason: Reason
        var id: String { after?.id ?? before!.id }
        var title: String { after?.title ?? before!.title }
        var transactionID: UUID { after?.transactionID ?? before!.transactionID }
        var effect: Decimal { (after?.signedAmount ?? 0) - (before?.signedAmount ?? 0) }
    }
    struct Comparison {
        let before: Snapshot
        let after: Snapshot
        let changes: [Change]
        var difference: Decimal { after.net - before.net }
        var salaryChanged: Bool { before.salaryID != after.salaryID || before.payday != after.payday }
        var startDateChanged: Bool { before.startDate != after.startDate }
    }

    static func compare(_ before: Snapshot, _ after: Snapshot, transactions: [Transaction]) -> Comparison {
        var remaining = after.lines
        var changes: [Change] = []
        for old in before.lines {
            // Match exact occurrence first, then a moved explicit transaction (not another projected occurrence).
            let index = remaining.firstIndex { $0.id == old.id }
                ?? remaining.firstIndex { !$0.projected && !old.projected && $0.transactionID == old.transactionID }
            if let index {
                let new = remaining.remove(at: index)
                let reason: Reason?
                if old.income != new.income { reason = .typeChanged }
                else if old.amount != new.amount { reason = .amountChanged }
                else if old.date != new.date { reason = .dateChanged }
                else if old.title != new.title { reason = .titleChanged }
                else if old.projected && !new.projected { reason = .occurrenceRegistered }
                else { reason = nil }
                if let reason { changes.append(Change(before: old, after: new, reason: reason)) }
            } else {
                let record = transactions.first { $0.id == old.transactionID }
                let reason: Reason
                // A settled template does not mean its generated future occurrence was settled.
                if !old.projected, let record {
                    if record.isArchived { reason = .archived }
                    else if record.status == .cancelled { reason = .cancelled }
                    else if record.isSettled { reason = old.income ? .received : .paid }
                    else { reason = .noLongerIncluded }
                } else { reason = .noLongerIncluded }
                changes.append(Change(before: old, after: nil, reason: reason))
            }
        }
        changes += remaining.map { Change(before: nil, after: $0, reason: .included) }
        changes.sort {
            let left = $0.effect < 0 ? -$0.effect : $0.effect
            let right = $1.effect < 0 ? -$1.effect : $1.effect
            return left == right ? $0.id < $1.id : left > right
        }
        return Comparison(before: before, after: after, changes: changes)
    }
}

@MainActor
@Observable
final class ForecastChangeHistory {
    private(set) var baseline: ForecastChanges.Snapshot?
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let key: String
    init(defaults: UserDefaults = .standard, key: String) {
        self.defaults = defaults
        self.key = key
        if let data = defaults.data(forKey: key), let snapshot = try? JSONDecoder().decode(ForecastChanges.Snapshot.self, from: data), snapshot.isValid {
            baseline = snapshot
        }
    }
    static func live() -> ForecastChangeHistory {
        ForecastChangeHistory(key: AppLaunchConfiguration.usesIsolatedTestStore ? "forecast.changes.test.baseline" : "forecast.changes.baseline")
    }
    func ensureBaseline(_ snapshot: ForecastChanges.Snapshot) {
        if baseline == nil { save(snapshot) }
    }
    func save(_ snapshot: ForecastChanges.Snapshot) {
        guard snapshot.isValid, let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
        baseline = snapshot
    }
}
