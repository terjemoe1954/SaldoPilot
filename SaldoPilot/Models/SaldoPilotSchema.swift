//
//  SaldoPilotSchema.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import Foundation
import SwiftData

enum SaldoPilotSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Transaction.self]
    }

    @Model
    final class Transaction {
        var id: UUID = UUID()
        var title: String = ""
        var amount: Decimal = Decimal.zero
        var type: TransactionType = TransactionType.expense
        var dueDate: Date = Date.now
        var paidDate: Date?
        var status: TransactionStatus = TransactionStatus.pending
        var category: CategoryKind = CategoryKind.other
        var recurrence: RecurrenceRule = RecurrenceRule.none
        var recurrenceIntervalMonths: Int?
        var notes: String = ""
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now
        var isCompleted: Bool = false
        var isArchived: Bool = false

        init(
            id: UUID = UUID(),
            title: String,
            amount: Decimal,
            type: TransactionType,
            dueDate: Date,
            paidDate: Date? = nil,
            status: TransactionStatus = .pending,
            category: CategoryKind = .other,
            recurrence: RecurrenceRule = .none,
            recurrenceIntervalMonths: Int? = nil,
            notes: String = "",
            createdAt: Date = .now,
            updatedAt: Date = .now,
            isCompleted: Bool = false,
            isArchived: Bool = false
        ) {
            self.id = id
            self.title = title
            self.amount = amount
            self.type = type
            self.dueDate = dueDate
            self.paidDate = paidDate
            self.status = status
            self.category = category
            self.recurrence = recurrence
            self.recurrenceIntervalMonths = recurrenceIntervalMonths
            self.notes = notes
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.isCompleted = isCompleted
            self.isArchived = isArchived
        }
    }
}

enum SaldoPilotSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 1, 0) }

    static var models: [any PersistentModel.Type] {
        [Transaction.self, Budget.self]
    }

    @Model
    final class Transaction {
        var id: UUID = UUID()
        var title: String = ""
        var amount: Decimal = Decimal.zero
        var type: TransactionType = TransactionType.expense
        var dueDate: Date = Date.now
        var paidDate: Date?
        var status: TransactionStatus = TransactionStatus.pending
        var category: CategoryKind = CategoryKind.other
        var recurrence: RecurrenceRule = RecurrenceRule.none
        var recurrenceIntervalMonths: Int?
        var notes: String = ""
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now
        var isCompleted: Bool = false
        var isArchived: Bool = false

        init(
            id: UUID = UUID(),
            title: String,
            amount: Decimal,
            type: TransactionType,
            dueDate: Date,
            paidDate: Date? = nil,
            status: TransactionStatus = .pending,
            category: CategoryKind = .other,
            recurrence: RecurrenceRule = .none,
            recurrenceIntervalMonths: Int? = nil,
            notes: String = "",
            createdAt: Date = .now,
            updatedAt: Date = .now,
            isCompleted: Bool = false,
            isArchived: Bool = false
        ) {
            self.id = id
            self.title = title
            self.amount = amount
            self.type = type
            self.dueDate = dueDate
            self.paidDate = paidDate
            self.status = status
            self.category = category
            self.recurrence = recurrence
            self.recurrenceIntervalMonths = recurrenceIntervalMonths
            self.notes = notes
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.isCompleted = isCompleted
            self.isArchived = isArchived
        }
    }

    @Model
    final class Budget {
        var id: UUID = UUID()
        var category: CategoryKind = CategoryKind.other
        var monthStart: Date = Date.now
        var amount: Decimal = Decimal.zero
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now

        init(
            id: UUID = UUID(),
            category: CategoryKind,
            monthStart: Date,
            amount: Decimal,
            createdAt: Date = .now,
            updatedAt: Date = .now
        ) {
            self.id = id
            self.category = category
            self.monthStart = monthStart
            self.amount = amount
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }
}

enum SaldoPilotSchemaV3: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 2, 0) }

    static var models: [any PersistentModel.Type] {
        [Transaction.self, Budget.self]
    }

    // Keep released schemas self-contained. Resolving these names to the current
    // V4 models changes the V3 checksum and makes existing stores unrecognizable.
    @Model
    final class Transaction {
        var id: UUID = UUID()
        var title: String = ""
        var amount: Decimal = Decimal.zero
        var type: TransactionType = TransactionType.expense
        var dueDate: Date = Date.now
        var paidDate: Date?
        var status: TransactionStatus = TransactionStatus.pending
        var category: CategoryKind = CategoryKind.other
        var recurrence: RecurrenceRule = RecurrenceRule.none
        var recurrenceIntervalMonths: Int?
        var recurrenceSeriesID: UUID?
        var recurrenceAnchorDay: Int?
        var notes: String = ""
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now
        var isCompleted: Bool = false
        var isArchived: Bool = false

        var effectiveStatus: TransactionStatus {
            guard status == .pending, !isCompleted else {
                return status
            }

            return dueDate < Calendar.current.startOfDay(for: .now) ? .overdue : status
        }

        var isSettled: Bool {
            isCompleted || status == .paid || status == .received
        }

        /// Transfers to savings and balance corrections are not ordinary income or spending.
        var isIncludedInOrdinaryCashFlow: Bool {
            guard category != .savings else { return false }
            if category == .refund, type != .income { return false }
            let normalizedTitle = title.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            ).lowercased()
            return !normalizedTitle.contains("saldojustering")
                && !normalizedTitle.contains("balance adjustment")
        }

        /// Refunds remain visible in category breakdowns even if entered as an expense.
        var isIncludedInCategoryActivity: Bool {
            isIncludedInOrdinaryCashFlow || category == .refund
        }

        init(
            id: UUID = UUID(),
            title: String,
            amount: Decimal,
            type: TransactionType,
            dueDate: Date,
            paidDate: Date? = nil,
            status: TransactionStatus = .pending,
            category: CategoryKind = .other,
            recurrence: RecurrenceRule = .none,
            recurrenceIntervalMonths: Int? = nil,
            recurrenceSeriesID: UUID? = nil,
            recurrenceAnchorDay: Int? = nil,
            notes: String = "",
            createdAt: Date = .now,
            updatedAt: Date = .now,
            isCompleted: Bool = false,
            isArchived: Bool = false
        ) {
            self.id = id
            self.title = title
            self.amount = amount
            self.type = type
            self.dueDate = dueDate
            self.paidDate = paidDate
            self.status = status
            self.category = category
            self.recurrence = recurrence
            self.recurrenceIntervalMonths = recurrenceIntervalMonths
            self.recurrenceSeriesID = recurrenceSeriesID
            self.recurrenceAnchorDay = recurrenceAnchorDay
            self.notes = notes
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.isCompleted = isCompleted
            self.isArchived = isArchived
        }

        func markUpdated(at date: Date = .now) {
            updatedAt = date
        }
    }

    @Model
    final class Budget {
        var id: UUID = UUID()
        var category: CategoryKind = CategoryKind.other
        var monthStart: Date = Date.now
        var amount: Decimal = Decimal.zero
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now

        init(
            id: UUID = UUID(),
            category: CategoryKind,
            monthStart: Date,
            amount: Decimal,
            createdAt: Date = .now,
            updatedAt: Date = .now
        ) {
            self.id = id
            self.category = category
            self.monthStart = monthStart
            self.amount = amount
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }

        func markUpdated(at date: Date = .now) {
            updatedAt = date
        }
    }
}

enum SaldoPilotSchemaV4: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 3, 0) }

    static var models: [any PersistentModel.Type] {
        [Transaction.self, Budget.self, CategoryDefinition.self]
    }


@Model
final class Transaction {
    var id: UUID = UUID()
    var title: String = ""
    var amount: Decimal = Decimal.zero
    var type: TransactionType = TransactionType.expense
    var dueDate: Date = Date.now
    var paidDate: Date?
    var status: TransactionStatus = TransactionStatus.pending
    var category: CategoryKind = CategoryKind.other
    var customCategoryID: String?
    var recurrence: RecurrenceRule = RecurrenceRule.none
    var recurrenceIntervalMonths: Int?
    var recurrenceSeriesID: UUID?
    var recurrenceAnchorDay: Int?
    var notes: String = ""
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var isCompleted: Bool = false
    var isArchived: Bool = false

    var effectiveStatus: TransactionStatus {
        guard status == .pending, !isCompleted else {
            return status
        }

        return dueDate < Calendar.current.startOfDay(for: .now) ? .overdue : status
    }

    var isSettled: Bool {
        isCompleted || status == .paid || status == .received
    }

    /// Transfers to savings and balance corrections are not ordinary income or spending.
    var isIncludedInOrdinaryCashFlow: Bool {
        guard category != .savings else { return false }
        if category == .refund, type != .income { return false }
        let normalizedTitle = title.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        ).lowercased()
        return !normalizedTitle.contains("saldojustering")
            && !normalizedTitle.contains("balance adjustment")
    }

    /// Refunds remain visible in category breakdowns even if entered as an expense.
    var isIncludedInCategoryActivity: Bool {
        isIncludedInOrdinaryCashFlow || category == .refund
    }

    init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        type: TransactionType,
        dueDate: Date,
        paidDate: Date? = nil,
        status: TransactionStatus = .pending,
        category: CategoryKind = .other,
        customCategoryID: String? = nil,
        recurrence: RecurrenceRule = .none,
        recurrenceIntervalMonths: Int? = nil,
        recurrenceSeriesID: UUID? = nil,
        recurrenceAnchorDay: Int? = nil,
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isCompleted: Bool = false,
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.type = type
        self.dueDate = dueDate
        self.paidDate = paidDate
        self.status = status
        self.category = category
        self.customCategoryID = customCategoryID
        self.recurrence = recurrence
        self.recurrenceIntervalMonths = recurrenceIntervalMonths
        self.recurrenceSeriesID = recurrenceSeriesID
        self.recurrenceAnchorDay = recurrenceAnchorDay
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isCompleted = isCompleted
        self.isArchived = isArchived
    }

    var categoryID: String {
        customCategoryID ?? category.rawValue
    }

    func markUpdated(at date: Date = .now) {
        updatedAt = date
    }
}

@Model
final class Budget {
    var id: UUID = UUID()
    var category: CategoryKind = CategoryKind.other
    var customCategoryID: String?
    var monthStart: Date = Date.now
    var amount: Decimal = Decimal.zero
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    init(
        id: UUID = UUID(),
        category: CategoryKind,
        customCategoryID: String? = nil,
        monthStart: Date,
        amount: Decimal,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.category = category
        self.customCategoryID = customCategoryID
        self.monthStart = monthStart
        self.amount = amount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var categoryID: String {
        customCategoryID ?? category.rawValue
    }

    func markUpdated(at date: Date = .now) {
        updatedAt = date
    }
}

@Model
    final class CategoryDefinition {
        var id: String = UUID().uuidString
        var name: String = ""
        var systemImage: String = "tag"
        var colorName: String = "blue"
        var legacyKindRawValue: String?
        var isHidden: Bool = false
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now

        init(
            id: String = UUID().uuidString,
            name: String,
            systemImage: String = "tag",
            colorName: String = "blue",
            legacyKindRawValue: String? = nil,
            isHidden: Bool = false,
            createdAt: Date = .now,
            updatedAt: Date = .now
        ) {
            self.id = id
            self.name = name
            self.systemImage = systemImage
            self.colorName = colorName
            self.legacyKindRawValue = legacyKindRawValue
            self.isHidden = isHidden
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }
}

enum SaldoPilotSchemaV5: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 4, 0) }
    static var models: [any PersistentModel.Type] {
        [Transaction.self, Budget.self, CategoryDefinition.self]
    }
}

enum SaldoPilotSchemaV6: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 5, 0) }
    static var models: [any PersistentModel.Type] { SaldoPilotSchemaV5.models + [ExternalImportReceipt.self] }
}

enum SaldoPilotSchemaV7: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 6, 0) }
    static var models: [any PersistentModel.Type] { SaldoPilotSchemaV6.models + [SavingsGoal.self] }
}

enum SaldoPilotMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            SaldoPilotSchemaV1.self,
            SaldoPilotSchemaV2.self,
            SaldoPilotSchemaV3.self,
            SaldoPilotSchemaV4.self,
            SaldoPilotSchemaV5.self,
            SaldoPilotSchemaV6.self,
            SaldoPilotSchemaV7.self
        ]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(
                fromVersion: SaldoPilotSchemaV1.self,
                toVersion: SaldoPilotSchemaV2.self
            ),
            .lightweight(
                fromVersion: SaldoPilotSchemaV2.self,
                toVersion: SaldoPilotSchemaV3.self
            ),
            .lightweight(
                fromVersion: SaldoPilotSchemaV3.self,
                toVersion: SaldoPilotSchemaV4.self
            ),
            .lightweight(fromVersion: SaldoPilotSchemaV4.self, toVersion: SaldoPilotSchemaV5.self),
            .lightweight(fromVersion: SaldoPilotSchemaV5.self, toVersion: SaldoPilotSchemaV6.self),
            .lightweight(fromVersion: SaldoPilotSchemaV6.self, toVersion: SaldoPilotSchemaV7.self)
        ]
    }
}
