//
//  SampleData.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import Foundation

enum SampleData {
    static func transactions() -> [Transaction] {
        [
            Transaction(
                title: "Husleie",
                amount: 14500,
                type: .expense,
                dueDate: .now,
                category: .home,
                recurrence: .monthly,
                recurrenceIntervalMonths: 1
            ),
            Transaction(
                title: "Lønn",
                amount: 42000,
                type: .income,
                dueDate: .now,
                status: .received,
                category: .income,
                isCompleted: true
            ),
            Transaction(
                title: "Strømmetjeneste",
                amount: 129,
                type: .expense,
                dueDate: .now,
                category: .subscriptions,
                recurrence: .monthly,
                recurrenceIntervalMonths: 1
            )
        ]
    }
}
