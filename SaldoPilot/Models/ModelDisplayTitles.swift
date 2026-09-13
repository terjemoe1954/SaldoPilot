//
//  ModelDisplayTitles.swift
//  SaldoPilot
//
//  Created by Terje Moe on 13/09/2026.
//

import SwiftUI

extension TransactionType {
    var title: LocalizedStringKey {
        switch self {
        case .income:
            "Income"
        case .expense:
            "Expense"
        }
    }
}

extension TransactionStatus {
    var title: LocalizedStringKey {
        switch self {
        case .pending:
            "Pending"
        case .overdue:
            "Overdue"
        case .paid:
            "Paid"
        case .received:
            "Received"
        case .cancelled:
            "Cancelled"
        }
    }
}

extension RecurrenceRule {
    var title: LocalizedStringKey {
        switch self {
        case .none:
            "None"
        case .monthly:
            "Monthly"
        case .everyNMonths:
            "Every few months"
        case .quarterly:
            "Quarterly"
        case .halfYearly:
            "Every six months"
        case .yearly:
            "Yearly"
        case .custom:
            "Custom"
        }
    }
}
