//
//  RecurrenceRule.swift
//  SaldoPilot
//
//  Created by Terje Moe on 12/09/2026.
//

import Foundation

enum RecurrenceRule: String, Codable, CaseIterable, Identifiable, Sendable {
    case none
    case monthly
    case everyNMonths
    case quarterly
    case halfYearly
    case yearly
    case custom

    var id: String { rawValue }
}
