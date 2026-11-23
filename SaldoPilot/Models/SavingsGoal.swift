import Foundation
import SwiftData

/// Goals track earmarked savings only; they never create cash-flow transactions.
@Model
final class SavingsGoal {
    var id: UUID = UUID()
    var name: String = ""
    var targetAmount: Decimal = Decimal.zero
    var savedAmount: Decimal = Decimal.zero
    var targetDate: Date?
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    // A tombstone prevents an older merged backup from resurrecting a deleted goal.
    var isDeleted: Bool = false

    init(id: UUID = UUID(), name: String, targetAmount: Decimal, savedAmount: Decimal = .zero,
         targetDate: Date? = nil, createdAt: Date = .now, updatedAt: Date = .now, isDeleted: Bool = false) {
        self.id = id; self.name = name; self.targetAmount = targetAmount; self.savedAmount = savedAmount
        self.targetDate = targetDate; self.createdAt = createdAt; self.updatedAt = updatedAt; self.isDeleted = isDeleted
    }
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(1, max(0, NSDecimalNumber(decimal: savedAmount / targetAmount).doubleValue))
    }
    var remaining: Decimal { max(.zero, targetAmount - savedAmount) }
}

struct SavingsGoalRecord: Codable {
    let id: UUID
    let name: String
    let targetAmount: Decimal
    let savedAmount: Decimal
    // Reference timestamps preserve subsecond values across a backup/restore cycle.
    let targetDate: Double?
    let createdAt: Double
    let updatedAt: Double
    let isDeleted: Bool
    init(_ goal: SavingsGoal) {
        id = goal.id; name = goal.name; targetAmount = goal.targetAmount; savedAmount = goal.savedAmount
        targetDate = goal.targetDate?.timeIntervalSinceReferenceDate
        createdAt = goal.createdAt.timeIntervalSinceReferenceDate
        updatedAt = goal.updatedAt.timeIntervalSinceReferenceDate; isDeleted = goal.isDeleted
    }
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count <= 120
        && !targetAmount.isNaN && !savedAmount.isNaN && targetAmount > 0 && savedAmount >= 0
        && createdAt.isFinite && updatedAt.isFinite && (targetDate?.isFinite ?? true)
    }
    func makeGoal() -> SavingsGoal {
        SavingsGoal(id: id, name: name, targetAmount: targetAmount, savedAmount: savedAmount,
                    targetDate: targetDate.map(Date.init(timeIntervalSinceReferenceDate:)),
                    createdAt: Date(timeIntervalSinceReferenceDate: createdAt),
                    updatedAt: Date(timeIntervalSinceReferenceDate: updatedAt), isDeleted: isDeleted)
    }
}

@MainActor
enum SavingsGoalSelection {
    /// SwiftData/CloudKit may briefly contain multiple objects with the same logical ID.
    /// Always choose one deterministic version without trapping or summing duplicates.
    static func preferred(_ goals: [SavingsGoal]) -> [SavingsGoal] {
        let groups = Dictionary(grouping: goals, by: \.id)
        return groups.values.compactMap { rows in rows.sorted(by: precedes).first }
            .sorted { $0.createdAt == $1.createdAt ? $0.id.uuidString < $1.id.uuidString : $0.createdAt < $1.createdAt }
    }
    private static func precedes(_ lhs: SavingsGoal, _ rhs: SavingsGoal) -> Bool {
        if lhs.updatedAt != rhs.updatedAt { return lhs.updatedAt > rhs.updatedAt }
        if lhs.isDeleted != rhs.isDeleted { return lhs.isDeleted }
        let a = [lhs.name, lhs.targetAmount.description, lhs.savedAmount.description, lhs.targetDate?.description ?? "", lhs.createdAt.description].joined(separator: "|")
        let b = [rhs.name, rhs.targetAmount.description, rhs.savedAmount.description, rhs.targetDate?.description ?? "", rhs.createdAt.description].joined(separator: "|")
        return a > b
    }
    static func save(_ goal: SavingsGoal?, name: String, target: Decimal, saved: Decimal, date: Date?, in context: ModelContext) throws {
        let item = goal ?? SavingsGoal(name: name, targetAmount: target, savedAmount: saved, targetDate: date)
        let candidate = SavingsGoal(name: name, targetAmount: target, savedAmount: saved, targetDate: date)
        guard SavingsGoalRecord(candidate).isValid else { throw BackupImportError.invalidBackup }
        if goal == nil { context.insert(item) }
        item.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        item.targetAmount = target; item.savedAmount = saved; item.targetDate = date; item.updatedAt = .now
        do { try context.save() } catch { context.rollback(); throw error }
    }
    static func delete(_ goal: SavingsGoal, in context: ModelContext) throws {
        let copies = try context.fetch(FetchDescriptor<SavingsGoal>()).filter { $0.id == goal.id }
        let now = Date.now
        for item in copies { item.isDeleted = true; item.updatedAt = now }
        do { try context.save() } catch { context.rollback(); throw error }
    }
}
