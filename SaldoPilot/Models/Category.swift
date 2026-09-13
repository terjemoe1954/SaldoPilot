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
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var colorIdentifier: String?
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]

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
