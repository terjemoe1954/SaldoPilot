//
//  TransactionType.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import Foundation

enum TransactionType: String, Codable, CaseIterable, Identifiable, Sendable {
    case income
    case expense

    var id: String { rawValue }
}
