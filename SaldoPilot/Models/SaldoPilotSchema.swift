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
}

enum SaldoPilotMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            SaldoPilotSchemaV1.self,
            SaldoPilotSchemaV2.self,
            SaldoPilotSchemaV3.self
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
            )
        ]
    }
}
