//
//  Category.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "tag"
    var colorIdentifier: String?
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]?

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "tag",
        colorIdentifier: String? = nil,
        createdAt: Date = .now,
        transactions: [Transaction] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorIdentifier = colorIdentifier
        self.createdAt = createdAt
        self.transactions = transactions
    }
}
