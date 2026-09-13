//
//  TransactionStatus.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import Foundation

enum TransactionStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case pending
    case overdue
    case paid
    case received
    case cancelled

    var id: String { rawValue }
}
