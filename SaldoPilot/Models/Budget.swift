//
//  Budget.swift
//  SaldoPilot
//
//  Created by Codex on 24/09/2026.
//

import Foundation
import SwiftData

typealias Budget = SaldoPilotSchemaV4.Budget

extension SaldoPilotSchemaV4 {
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
}
