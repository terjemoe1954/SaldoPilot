//
//  SampleData.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import Foundation

enum SampleData {
    static func categories() -> [Category] {
        [
            Category(name: "Bolig", icon: "house", colorIdentifier: "blue"),
            Category(name: "Lønn", icon: "banknote", colorIdentifier: "green"),
            Category(name: "Abonnement", icon: "repeat", colorIdentifier: "purple")
        ]
    }

    static func transactions(categories: [Category]) -> [Transaction] {
        let housing = categories.first { $0.name == "Bolig" }
        let salary = categories.first { $0.name == "Lønn" }
        let subscription = categories.first { $0.name == "Abonnement" }

        return [
            Transaction(
                title: "Husleie",
                amount: 14500,
                type: .expense,
                dueDate: .now,
                category: housing,
                recurrence: .monthly,
                recurrenceIntervalMonths: 1
            ),
            Transaction(
                title: "Lønn",
                amount: 42000,
                type: .income,
                dueDate: .now,
                status: .received,
                category: salary,
                isCompleted: true
            ),
            Transaction(
                title: "Strømmetjeneste",
                amount: 129,
                type: .expense,
                dueDate: .now,
                category: subscription,
                recurrence: .monthly,
                recurrenceIntervalMonths: 1
            )
        ]
    }
}
