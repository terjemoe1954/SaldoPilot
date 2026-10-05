//
//  Budget.swift
//  SaldoPilot
//
//  Created by Codex on 24/09/2026.
//

import Foundation
import SwiftData

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
