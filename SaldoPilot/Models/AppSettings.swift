//
//  AppSettings.swift
//  SaldoPilot
//
//  Created by Terje Moe on 13/09/2026.
//

import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .system:
            "System"
        case .light:
            "Light"
        case .dark:
            "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

enum AppDefaultPeriod: String, CaseIterable, Identifiable {
    case thisMonth
    case previousMonth
    case thisYear
    case custom

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .thisMonth:
            "This month"
        case .previousMonth:
            "Previous month"
        case .thisYear:
            "This year"
        case .custom:
            "Custom"
        }
    }
}

enum AppDefaultDateType: String, CaseIterable, Identifiable {
    case dueDate
    case paidDate

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .dueDate:
            "Due date"
        case .paidDate:
            "Paid date"
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case norwegian
    case thai

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .system:
            "System"
        case .english:
            "English"
        case .norwegian:
            "Norwegian"
        case .thai:
            "Thai"
        }
    }

    var locale: Locale {
        switch self {
        case .system:
            .autoupdatingCurrent
        case .english:
            Locale(identifier: "en")
        case .norwegian:
            Locale(identifier: "nb")
        case .thai:
            Locale(identifier: "th")
        }
    }
}

enum AppProStatus: String, CaseIterable, Identifiable {
    case free
    case pro

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .free:
            "Free"
        case .pro:
            "SaldoPilot Pro"
        }
    }

    var isProUnlocked: Bool {
        self == .pro
    }
}

enum AppSettingsKey {
    static let appearance = "settings.appearance"
    static let language = "settings.language"
    static let showNameOnDashboard = "settings.showNameOnDashboard"
    static let displayName = "settings.displayName"
    static let showCompletedStatus = "settings.showCompletedStatus"
    static let showSettledTransactions = "settings.showSettledTransactions"
    static let defaultPeriod = "settings.defaultPeriod"
    static let defaultDateType = "settings.defaultDateType"
    static let notifyDueToday = "settings.notifyDueToday"
    static let notifyDueTomorrow = "settings.notifyDueTomorrow"
    static let notifyDueInAdvance = "settings.notifyDueInAdvance"
    static let notificationAdvanceDays = "settings.notificationAdvanceDays"
    static let notifyPendingIncome = "settings.notifyPendingIncome"
    static let allowExternalAI = "settings.allowExternalAI"
    static let proStatus = "settings.proStatus"
}
